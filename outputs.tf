output "instance_id" {
  description = "EC2 instance ID"
  value       = aws_instance.k3s.id
}

output "instance_public_ip" {
  description = "Public IP of EC2 instance"
  value       = aws_instance.k3s.public_ip
}

output "app_url" {
  description = "Application URL"
  value       = "http://${aws_instance.k3s.public_ip}:30080"
}

output "argocd_url" {
  description = "Argo CD UI URL"
  value       = "https://${aws_instance.k3s.public_ip}:30443"
}

output "ssh_command" {
  description = "SSH command"
  value       = "ssh -i ~/.ssh/id_rsa ubuntu@${aws_instance.k3s.public_ip}"
}

output "important_info" {
  description = "Important information"
  value = <<-EOT
  
  ========================================
  🎉 Alexander Yasheyev JB CI-CD Project Deployed!
  ========================================
  
  📦 Application:
     ${aws_instance.k3s.public_ip}:30080
  
  🚀 Argo CD UI:
     https://${aws_instance.k3s.public_ip}:30443
     Username: admin
     Password: SSH to instance and run:
              cat /home/ubuntu/argocd-password.txt
  
  💻 SSH:
     ssh -i ~/.ssh/id_rsa ubuntu@${aws_instance.k3s.public_ip}
  
  📋 Cluster Info:
     cat /home/ubuntu/cluster-info.txt
  
  ⏰ Wait 5-10 minutes for full setup!
  
  ========================================
  EOT
}
