#!/usr/bin/env python3
import subprocess
import json
import re
from datetime import datetime
from collections import defaultdict

class EnhancedDaprLogAnalyzer:
    def __init__(self):
        self.insights = {
            'scheduler_errors': {
                'pattern': r'Failed to connect to scheduler host',
                'severity': 'warning',
                'solution': 'Add dapr.io/config: "dapr-config" annotation and disable scheduler',
                'impact': 'Non-critical - scheduler is optional for pub/sub'
            },
            'component_errors': {
                'pattern': r'error loading component|component initialization failed',
                'severity': 'high',
                'solution': 'Check component YAML configuration and AWS credentials',
                'impact': 'Critical - affects pub/sub functionality'
            },
            'pubsub_success': {
                'pattern': r'component loaded successfully.*pubsub',
                'severity': 'info',
                'solution': 'No action needed',
                'impact': 'Positive - pub/sub is working'
            },
            'sidecar_ready': {
                'pattern': r'dapr initialized|application discovered on port',
                'severity': 'info',
                'solution': 'No action needed',
                'impact': 'Positive - Dapr sidecar is healthy'
            }
        }
    
    def get_pod_logs(self, app_name, container='daprd', lines=100):
        try:
            cmd = f"kubectl logs -l app={app_name} -c {container} --tail={lines}"
            result = subprocess.run(cmd.split(), capture_output=True, text=True)
            return result.stdout
        except Exception as e:
            return f"Error: {e}"
    
    def analyze_logs_advanced(self, logs, service_name):
        analysis = {
            'service': service_name,
            'status': 'unknown',
            'issues': defaultdict(int),
            'recommendations': [],
            'health_score': 100
        }
        
        lines = logs.split('\n')
        total_lines = len([l for l in lines if l.strip()])
        
        for pattern_name, config in self.insights.items():
            matches = len(re.findall(config['pattern'], logs, re.IGNORECASE))
            if matches > 0:
                analysis['issues'][pattern_name] = matches
                
                if config['severity'] == 'high':
                    analysis['health_score'] -= 30
                elif config['severity'] == 'warning':
                    analysis['health_score'] -= 5
                elif config['severity'] == 'info' and 'success' in pattern_name:
                    analysis['health_score'] += 10
        
        # Determine overall status
        if analysis['health_score'] >= 80:
            analysis['status'] = 'healthy'
        elif analysis['health_score'] >= 60:
            analysis['status'] = 'degraded'
        else:
            analysis['status'] = 'unhealthy'
        
        # Generate recommendations
        for issue, count in analysis['issues'].items():
            if count > 0 and self.insights[issue]['severity'] in ['high', 'warning']:
                analysis['recommendations'].append({
                    'issue': issue,
                    'count': count,
                    'solution': self.insights[issue]['solution'],
                    'impact': self.insights[issue]['impact']
                })
        
        return analysis
    
    def generate_enhanced_report(self):
        services = ['product-service', 'order-service']
        report = {
            'timestamp': datetime.now().isoformat(),
            'cluster_health': 'unknown',
            'services': {},
            'summary': {
                'total_issues': 0,
                'critical_issues': 0,
                'recommendations': []
            }
        }
        
        for service in services:
            print(f"🔍 Analyzing {service}...")
            
            dapr_logs = self.get_pod_logs(service, 'daprd')
            app_logs = self.get_pod_logs(service, service)
            
            dapr_analysis = self.analyze_logs_advanced(dapr_logs, f"{service}-dapr")
            app_analysis = self.analyze_logs_advanced(app_logs, f"{service}-app")
            
            report['services'][service] = {
                'dapr': dapr_analysis,
                'application': app_analysis
            }
            
            # Update summary
            report['summary']['total_issues'] += len(dapr_analysis['issues']) + len(app_analysis['issues'])
            report['summary']['recommendations'].extend(dapr_analysis['recommendations'])
        
        # Determine cluster health
        avg_health = sum([
            data['dapr']['health_score'] + data['application']['health_score']
            for data in report['services'].values()
        ]) / (len(report['services']) * 2)
        
        if avg_health >= 80:
            report['cluster_health'] = 'healthy'
        elif avg_health >= 60:
            report['cluster_health'] = 'degraded'
        else:
            report['cluster_health'] = 'unhealthy'
        
        return report
    
    def print_enhanced_insights(self, report):
        print(f"\n{'='*60}")
        print("🤖 AI-POWERED DAPR LOG ANALYSIS REPORT")
        print(f"{'='*60}")
        print(f"📅 Generated: {report['timestamp']}")
        print(f"🏥 Cluster Health: {report['cluster_health'].upper()}")
        print(f"📊 Total Issues: {report['summary']['total_issues']}")
        
        for service, data in report['services'].items():
            print(f"\n🔧 {service.upper()}:")
            
            # Dapr Analysis
            dapr = data['dapr']
            print(f"  📡 Dapr Sidecar: {dapr['status']} (Health: {dapr['health_score']}/100)")
            
            if dapr['issues']:
                for issue, count in dapr['issues'].items():
                    severity = self.insights[issue]['severity']
                    emoji = "🔴" if severity == 'high' else "🟡" if severity == 'warning' else "🟢"
                    print(f"    {emoji} {issue}: {count} occurrences")
            
            # Application Analysis  
            app = data['application']
            print(f"  🚀 Application: {app['status']} (Health: {app['health_score']}/100)")
        
        # Recommendations
        if report['summary']['recommendations']:
            print(f"\n💡 RECOMMENDATIONS:")
            for i, rec in enumerate(report['summary']['recommendations'][:5], 1):
                print(f"  {i}. {rec['solution']}")
                print(f"     Impact: {rec['impact']}")
        
        print(f"\n✅ Analysis complete. Run 'kubectl get pods' to check current status.")

if __name__ == "__main__":
    analyzer = EnhancedDaprLogAnalyzer()
    report = analyzer.generate_enhanced_report()
    analyzer.print_enhanced_insights(report)