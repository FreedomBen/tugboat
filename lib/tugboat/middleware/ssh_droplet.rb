module Tugboat
  module Middleware
    class SSHDroplet < Base
      def call(env)
        say "Executing SSH #{env["droplet_name"]}..."

        options = [
          "-o", "IdentitiesOnly=yes",
          "-o", "LogLevel=ERROR",
          "-o", "StrictHostKeyChecking=no",
          "-o", "UserKnownHostsFile=/dev/null",
          "-i", File.expand_path(env["config"].ssh_key_path.to_s)]

        if env["user_droplet_ssh_port"]
          options.push("-p", env["user_droplet_ssh_port"].to_s)
        elsif env["config"].ssh_port
          options.push("-p", env["config"].ssh_port.to_s)
        else
          options.push("-p", "22")
        end

        if env["user_droplet_ssh_opts"]
          options.concat env["user_droplet_ssh_opts"].split
        end

        ssh_user = env["user_droplet_ssh_user"] || env["config"].ssh_user

        host_ip = env["droplet_ip"]

        if env["droplet_ip_private"]
          use_public_ip = env["config"].use_public_ip

          if not env["user_droplet_use_public_ip"].nil?
            use_public_ip = env["user_droplet_use_public_ip"]
          end

          if not use_public_ip
            host_ip = env["droplet_ip_private"]
          end
        end

        host_string = "#{ssh_user}@#{host_ip}"

        say "SSH-ing as: #{host_string}", :green

        options << host_string

        if env["user_droplet_ssh_command"]
          options.push(env["user_droplet_ssh_command"])
        end

        Kernel.exec("ssh", *options)

        @app.call(env)
      end
    end
  end
end

