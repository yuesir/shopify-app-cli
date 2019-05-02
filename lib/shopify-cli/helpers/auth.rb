# frozen_string_literal: true
require 'base64'
require 'securerandom'
require 'socket'
require 'net/http'
require 'uri'
require 'json'
require 'digest'
require 'openssl'

module ShopifyCli
  module Helpers
    class Auth
      PORT = 3456
      REDIRECT_URI = "http://localhost:#{PORT}/"
      AUTH_URL = 'https://identity.myshopify.io/oauth/authorize'
      TOKEN_URL = 'https://identity.myshopify.io/oauth/token'
      CLIENT_ID = 'e5380e02-312a-7408-5718-e07017e9cf52'
      OPENID_SCOPE = "openid email profile"

      def initialize(ctx)
        @ctx = ctx || ShopifyCli::Context.new
      end

      def authenticate
        server = TCPServer.new('localhost', PORT)

        uri = URI.parse(AUTH_URL)
        uri.query = URI.encode_www_form(build_auth_code_query)
        @ctx.puts("opening #{uri}")
        @ctx.system("open '#{uri}'")

        code = wait_for_redirect(server)

        case res = send_token_request(code)
        when Net::HTTPSuccess
          store_token(res)
          @ctx.puts "{{success:Tokens stored!}}"
        else
          @ctx.puts("{{error:Response was #{res.body}}}")
          @ctx.puts("{{error:Failed to retrieve ID & Refresh tokens}}")
        end
      end

      def build_auth_code_query
        params = {
          response_type: "code",
          client_id: CLIENT_ID,
          redirect_uri: REDIRECT_URI,
          state: state_token,
          code_challenge: code_challenge,
          code_challenge_method: 'S256',
          scope: OPENID_SCOPE,
        }

        params
      end

      def wait_for_redirect(server)
        socket = server.accept # Wait for redirect
        @ctx.puts "Authenticated with Partner Dashboard"
        request = socket.gets

        unless extract_query_param('state', request) == state_token
          socket.close
          raise(StandardError, "Anti-forgery state token does not match the initial request.")
        end

        socket.print("HTTP/1.1 200\r\n")
        socket.print("Content-Type: text/plain\r\n\r\n")
        socket.print("SUCCESS - please return to the CLI for the rest of this process.")
        socket.close
        extract_query_param("code", request)
      end

      def send_token_request(code)
        uri = URI(TOKEN_URL)
        https = Net::HTTP.new(uri.host, uri.port)
        https.use_ssl = true
        request = Net::HTTP::Post.new(uri.path)
        request.body = URI.encode_www_form(
          grant_type: "authorization_code",
          code: code,
          redirect_uri: REDIRECT_URI, # A required parameter
          client_id: CLIENT_ID,
          code_verifier: code_verifier,
        )
        @ctx.puts "Fetching tokens..."
        https.request(request)
      end

      def store_token(res)
        body = JSON.parse(res.body)

        content = {
          token: body['access_token'],
          expires_at: Time.now + body['expires_in'],
        }

        File.write(File.join(ShopifyCli::ROOT, '.auth'), JSON.dump(content))
      end

      def extract_query_param(key, request)
        paramstring = request.split('?')[1]
        paramstring = paramstring.split(' ')[0]
        URI.decode_www_form(paramstring).assoc(key).last
      end

      def code_challenge
        @code_challenge ||= Base64.urlsafe_encode64(
          OpenSSL::Digest::SHA256.digest(code_verifier), padding: false
        )
      end

      def code_verifier
        @code_verifier ||= Base64.urlsafe_encode64(SecureRandom.hex(64), padding: false)
      end

      def state_token
        @state_token ||= SecureRandom.hex(30)
      end
    end
  end
end
