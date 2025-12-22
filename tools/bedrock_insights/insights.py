"""Generate deployment insights by calling Amazon Bedrock models (Claude + Titan).

This module exposes a small CLI that assembles project context, creates a
single, structured prompt, and then queries two Bedrock models to return
recommendations. It can run in "offline" mode for local testing without
making AWS calls.
"""
from __future__ import annotations

import argparse
import json
import os
import textwrap
from dataclasses import dataclass, field
from pathlib import Path
from typing import Dict, List, Optional

import boto3
from botocore.exceptions import BotoCoreError, ClientError

BEDROCK_REGION = os.getenv("BEDROCK_REGION", "us-east-1")
DEFAULT_CLAUDE_MODEL = os.getenv(
    "BEDROCK_CLAUDE_MODEL_ID", "anthropic.claude-3-sonnet-20240229-v1:0"
)
DEFAULT_TITAN_MODEL = os.getenv(
    "BEDROCK_TITAN_MODEL_ID", "amazon.titan-text-premier-v1:0"
)

DEFAULT_CONTEXT = textwrap.dedent(
    """
    Project: CNA-Introspect-1B
    Services: product-service (FastAPI publisher), order-service (FastAPI subscriber)
    Messaging: Dapr pub/sub via SNS topic + SQS queue, IRSA-enabled
    Platform: Amazon EKS, managed node group, Dapr sidecars, CloudWatch Observability
    Observed gaps: only basic logging, limited resiliency config, need scaling guidance
    Desired outputs: telemetry recommendations, retry/resiliency playbook,
    manifest/container analysis, SNS/SQS scaling strategy on EKS with Dapr.
    """
)

FOCUS_POINTS = [
    "Missing telemetry & observability hooks (metrics, traces, events)",
    "Retry, backoff, and resiliency for event-driven workloads",
    "Dockerfile + Kubernetes + Dapr component improvements",
    "Scaling guidance for SNS/SQS-driven pub/sub on EKS",
]


@dataclass
class InsightPromptBuilder:
    """Assemble the system context and desired focus areas into a single prompt."""

    focus_points: List[str] = field(
        default_factory=lambda: FOCUS_POINTS.copy())

    def render(self, context: str) -> str:
        bullet_list = "\n".join(f"- {item}" for item in self.focus_points)
        return textwrap.dedent(
            f"""
            You are an expert cloud architect. Given the project context below,
            craft concrete, actionable insights for each focus point.

            Context:
            {context.strip()}

            Focus:
            {bullet_list}

            Output format:
            - Use markdown headings per focus point (## Heading)
            - Provide bullet lists with rationale and next steps
            - Keep tone practical, cite AWS services / features when relevant
            """
        ).strip()


def _invoke_titan(client, prompt: str, model_id: str) -> str:
    body = {
        "inputText": prompt,
        "textGenerationConfig": {
            "maxTokenCount": 800,
            "temperature": 0.3,
            "topP": 0.9,
            "topK": 50,
        },
    }
    response = client.invoke_model(modelId=model_id, body=json.dumps(body))
    payload = json.loads(response["body"].read())
    return payload["results"][0]["outputText"].strip()


def _invoke_claude(client, prompt: str, model_id: str) -> str:
    body = {
        "anthropic_version": "bedrock-2023-05-31",
        "max_tokens": 800,
        "temperature": 0.2,
        "messages": [
            {
                "role": "user",
                "content": [
                    {
                        "type": "text",
                        "text": prompt,
                    }
                ],
            }
        ],
    }
    response = client.invoke_model(modelId=model_id, body=json.dumps(body))
    payload = json.loads(response["body"].read())
    text_segments = [block.get("text", "")
                     for block in payload.get("content", [])]
    return "\n".join(segment for segment in text_segments if segment).strip()


def _offline_response(model_name: str, prompt: str) -> str:
    snippet = prompt.strip().splitlines()[:6]
    snippet_text = " ".join(line.strip() for line in snippet)
    return textwrap.dedent(
        f"""
        [{model_name} OFFLINE SAMPLE]
        Unable to contact Bedrock in offline mode. This placeholder confirms
        that the prompt builder is wiring context correctly.
        Prompt preview: {snippet_text[:250]}...
        """
    ).strip()


def generate_insights(
    context: str,
    *,
    region: str = BEDROCK_REGION,
    claude_model: str = DEFAULT_CLAUDE_MODEL,
    titan_model: str = DEFAULT_TITAN_MODEL,
    offline: bool = False,
) -> Dict[str, str]:
    builder = InsightPromptBuilder()
    prompt = builder.render(context)

    if offline:
        return {
            "prompt": prompt,
            "claude": _offline_response("Claude", prompt),
            "titan": _offline_response("Titan", prompt),
        }

    client = boto3.client("bedrock-runtime", region_name=region)

    def safe_call(name: str, fn):
        try:
            return fn()
        except (BotoCoreError, ClientError) as exc:
            return f"[Error calling {name}: {exc}]"

    titan_output = safe_call(
        "Amazon Titan",
        lambda: _invoke_titan(client, prompt=prompt, model_id=titan_model),
    )
    claude_output = safe_call(
        "Claude",
        lambda: _invoke_claude(client, prompt=prompt, model_id=claude_model),
    )

    return {"prompt": prompt, "claude": claude_output, "titan": titan_output}


def _load_context_from_args(args: argparse.Namespace) -> str:
    if args.context_file:
        path = Path(args.context_file)
        if not path.exists():
            raise FileNotFoundError(f"Context file not found: {path}")
        return path.read_text()
    if args.context:
        return args.context
    return DEFAULT_CONTEXT


def _format_output(results: Dict[str, str]) -> str:
    divider = "\n" + ("=" * 80) + "\n"
    return (
        f"Prompt\n------\n{results['prompt']}"
        f"{divider}Claude Response\n---------------\n{results['claude']}"
        f"{divider}Amazon Titan Response\n-----------------------\n{results['titan']}"
    )


def main(argv: Optional[List[str]] = None) -> int:
    parser = argparse.ArgumentParser(
        description="Run Bedrock insight prompts.")
    parser.add_argument(
        "--context-file",
        help="Path to a markdown/text file describing the system context.",
    )
    parser.add_argument(
        "--context",
        help="Raw context text (overrides default and file).",
    )
    parser.add_argument(
        "--region",
        default=BEDROCK_REGION,
        help=f"Bedrock region (default: {BEDROCK_REGION}).",
    )
    parser.add_argument(
        "--claude-model",
        default=DEFAULT_CLAUDE_MODEL,
        help="Claude model ID (Bedrock).",
    )
    parser.add_argument(
        "--titan-model",
        default=DEFAULT_TITAN_MODEL,
        help="Amazon Titan model ID (Bedrock).",
    )
    parser.add_argument(
        "--offline",
        action="store_true",
        help="Do not call AWS; emit offline placeholder responses.",
    )
    args = parser.parse_args(argv)

    context = _load_context_from_args(args)
    results = generate_insights(
        context,
        region=args.region,
        claude_model=args.claude_model,
        titan_model=args.titan_model,
        offline=args.offline,
    )
    print(_format_output(results))
    return 0


if __name__ == "__main__":  # pragma: no cover
    raise SystemExit(main())
