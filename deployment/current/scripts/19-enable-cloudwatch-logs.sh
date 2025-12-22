#!/bin/bash
set -euo pipefail

AWS_PROFILE=${AWS_PROFILE:-selvam}
REGION=${AWS_REGION:-us-east-1}
CLUSTER_NAME=${CLUSTER_NAME:-cna-introspect-eks}
NAMESPACE="amazon-cloudwatch"
CONFIGMAP_NAME="aws-logging"
LOG_RETENTION_DAYS=${LOG_RETENTION_DAYS:-14}
APP_LOG_GROUP=${APP_LOG_GROUP:-/aws/eks/${CLUSTER_NAME}/application}
LOG_STREAM_PREFIX='${namespace_name}/${pod_name}/'
CLOUDWATCH_SA=${CLOUDWATCH_SA:-cloudwatch-agent}

echo "=== Enabling CloudWatch log shipping for workloads ==="

echo "Ensuring namespace '$NAMESPACE' exists..."
if ! kubectl get namespace "$NAMESPACE" >/dev/null 2>&1; then
  kubectl create namespace "$NAMESPACE"
else
  echo "Namespace $NAMESPACE already present"
fi

echo "Configuring IAM role for service account $NAMESPACE/$CLOUDWATCH_SA..."
eksctl create iamserviceaccount \
  --name $CLOUDWATCH_SA \
  --namespace $NAMESPACE \
  --cluster $CLUSTER_NAME \
  --attach-policy-arn arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy \
  --approve \
  --override-existing-serviceaccounts \
  --region $REGION \
  --profile $AWS_PROFILE || true

ensure_log_group() {
  local group_name="$1"
  if aws logs describe-log-groups \
      --profile "$AWS_PROFILE" \
      --region "$REGION" \
      --log-group-name-prefix "$group_name" \
      --query "logGroups[?logGroupName=='$group_name'].logGroupName" \
      --output text | grep -q "$group_name"; then
    echo "Log group $group_name already exists"
  else
    echo "Creating log group $group_name"
    aws logs create-log-group --log-group-name "$group_name" --profile "$AWS_PROFILE" --region "$REGION"
  fi

  echo "Setting retention policy for $group_name to $LOG_RETENTION_DAYS days"
  aws logs put-retention-policy --log-group-name "$group_name" --retention-in-days "$LOG_RETENTION_DAYS" --profile "$AWS_PROFILE" --region "$REGION" >/dev/null
}

ensure_log_group "$APP_LOG_GROUP"

echo "Applying CloudWatch Fluent Bit configuration..."
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: $CONFIGMAP_NAME
  namespace: $NAMESPACE
data:
  fluent-bit.conf: |
    [SERVICE]
        Flush        5
        Grace        30
        Log_Level    info
        Daemon       Off
        Parsers_File parsers.conf
        HTTP_Server  On
        HTTP_Listen  0.0.0.0
        HTTP_Port    2020

    [INPUT]
        Name              tail
        Tag               kube.*
        Path              /var/log/containers/*.log
        Parser            docker
        Refresh_Interval  10
        Mem_Buf_Limit     256MB
        Skip_Long_Lines   On
        Docker_Mode       On
        Docker_Mode_Flush 5

    [FILTER]
        Name                kubernetes
        Match               kube.*
        Merge_Log           On
        Keep_Log            Off
        K8S-Logging.Parser  On
        K8S-Logging.Exclude Off

    [FILTER]
        Name modify
        Match kube.*
        Rename log message

    [OUTPUT]
        Name              cloudwatch_logs
        Match             kube.*
    region            $REGION
    log_group_name    $APP_LOG_GROUP
    log_stream_prefix "$LOG_STREAM_PREFIX"
    auto_create_group false
    log_key           message
  parsers.conf: |
    [PARSER]
        Name        docker
        Format      json
        Time_Key    time
        Time_Format %Y-%m-%dT%H:%M:%S.%L
        Time_Keep   On
        Decode_Field_As escaped_utf8 log
EOF

if kubectl get daemonset -n "$NAMESPACE" >/dev/null 2>&1; then
  echo "Restarting CloudWatch Fluent Bit daemonsets to pick up new config..."
  for ds in $(kubectl get daemonset -n "$NAMESPACE" -o jsonpath='{.items[*].metadata.name}'); do
    kubectl -n "$NAMESPACE" rollout restart daemonset "$ds"
  done
else
  echo "No daemonsets found in $NAMESPACE yet. They will consume the config once created."
fi

echo "CloudWatch log streaming enabled. Check log group $APP_LOG_GROUP in region $REGION."
