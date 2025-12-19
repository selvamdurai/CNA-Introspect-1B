#!/usr/bin/env python3
import subprocess
import json
import re
from datetime import datetime

class DaprLogAnalyzer:
    def __init__(self):
        self.error_patterns = {
            'scheduler_connection': r'Failed to connect to scheduler host',
            'component_load_error': r'error loading component',
            'pubsub_error': r'error publishing message|error subscribing',
            'sidecar_startup': r'dapr initialized|application discovered',
            'http_errors': r'HTTP/1.1" [45]\d\d'
        }
    
    def get_pod_logs(self, app_name, container='daprd'):
        """Get logs from Dapr sidecar or application container"""
        try:
            cmd = f"kubectl logs -l app={app_name} -c {container} --tail=50"
            result = subprocess.run(cmd.split(), capture_output=True, text=True)
            return result.stdout
        except Exception as e:
            return f"Error getting logs: {e}"
    
    def analyze_logs(self, logs):
        """Analyze logs and provide insights"""
        insights = {
            'errors': [],
            'warnings': [],
            'status': 'healthy',
            'recommendations': []
        }
        
        lines = logs.split('\n')
        for line in lines:
            if 'scheduler host' in line and 'Failed to connect' in line:
                insights['errors'].append({
                    'type': 'scheduler_connection',
                    'message': 'Scheduler connection failed',
                    'recommendation': 'Disable scheduler in Dapr configuration'
                })
                insights['status'] = 'degraded'
            
            if 'error' in line.lower() and 'component' in line:
                insights['errors'].append({
                    'type': 'component_error',
                    'message': 'Component loading issue',
                    'recommendation': 'Check component configuration'
                })
            
            if 'dapr initialized' in line:
                insights['status'] = 'healthy'
        
        return insights
    
    def generate_report(self):
        """Generate comprehensive log analysis report"""
        services = ['product-service', 'order-service']
        report = {
            'timestamp': datetime.now().isoformat(),
            'services': {}
        }
        
        for service in services:
            print(f"Analyzing {service}...")
            
            # Analyze Dapr sidecar logs
            dapr_logs = self.get_pod_logs(service, 'daprd')
            dapr_analysis = self.analyze_logs(dapr_logs)
            
            # Analyze application logs
            app_logs = self.get_pod_logs(service, service)
            app_analysis = self.analyze_logs(app_logs)
            
            report['services'][service] = {
                'dapr': dapr_analysis,
                'application': app_analysis
            }
        
        return report
    
    def print_insights(self, report):
        """Print human-readable insights"""
        print("\n=== DAPR LOG ANALYSIS REPORT ===")
        print(f"Generated: {report['timestamp']}")
        
        for service, data in report['services'].items():
            print(f"\n🔍 {service.upper()}:")
            
            # Dapr sidecar status
            dapr_status = data['dapr']['status']
            print(f"  Dapr Status: {dapr_status}")
            
            if data['dapr']['errors']:
                print("  ❌ Dapr Issues:")
                for error in data['dapr']['errors']:
                    print(f"    - {error['message']}")
                    print(f"      💡 {error['recommendation']}")
            
            # Application status
            app_status = data['application']['status']
            print(f"  App Status: {app_status}")

if __name__ == "__main__":
    analyzer = DaprLogAnalyzer()
    report = analyzer.generate_report()
    analyzer.print_insights(report)