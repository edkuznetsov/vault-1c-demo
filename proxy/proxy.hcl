vault {
  address = "http://vault:8200"
}

auto_auth {
  method {
    type = "approle"

    config = {
      role_id_file_path                   = "/runtime/proxy/role-id"
      secret_id_file_path                 = "/runtime/proxy/secret-id"
      remove_secret_id_file_after_reading = false
    }
  }
}

api_proxy {
  # Proxy выделен одному приложению, поэтому клиентский Vault token игнорируется.
  use_auto_auth_token = "force"
}

listener "tcp" {
  # Внутри контейнера нужен 0.0.0.0; Compose публикует порт только на loopback хоста.
  address     = "0.0.0.0:8100"
  tls_disable = true
}
