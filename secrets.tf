resource "kubernetes_secret" "schematic" {
  metadata {
    name = "schematic-env"
    namespace="schematic"
  }
  data = {
    "SERVICE_ACCOUNT_CREDS" = jsonencode({
        "type"= var.sa_type,
        "project_id"= var.sa_project_id,
        "private_key_id"= var.sa_private_key_id,
        "private_key"= var.sa_private_key,
        "client_email"= var.sa_client_email,
        "client_id"= var.sa_client_id,
        "auth_uri"= var.sa_auth_uri,
        "token_uri"= var.sa_token_uri,
        "auth_provider_x509_cert_url"= var.sa_auth_provider_x509_cert_url,
        "client_x509_cert_url"= var.sa_client_x509_cert_url
    })
  }
}

resource "kubernetes_secret" "dca" {
  metadata {
    name = "dca-env"
    namespace="data-curator-app"
  }
  data = {
    "SECRETS_MANAGER_SECRETS" = jsonencode({
        "DCA_CLIENT_ID"= var.dca_client_id,
        "DCA_CLIENT_SECRET"= var.dca_client_secret,
        "DCA_APP_URL"= var.dca_app_url,
        "DCA_SCHEMATIC_API_TYPE"= var.dca_schematic_api_type
    })
  }
}
