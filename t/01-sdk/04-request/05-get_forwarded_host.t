use strict;
use warnings FATAL => 'all';
use Test::Nginx::Socket::Lua;
use File::Spec;

$ENV{TEST_NGINX_HTML_DIR} ||= html_dir();
$ENV{TEST_NGINX_CERT_DIR} ||= File::Spec->catdir(server_root(), '..', 'certs');

plan tests => repeat_each() * (blocks() * 3);

run_tests();

__DATA__

=== TEST 1: request.get_forwarded_host() returns host using host header from last hop when not trusted
--- config
    location = /t {
        access_by_lua_block {
            local SDK = require "kong.sdk"
            local sdk = SDK.new()

            ngx.say("host: ", sdk.request.get_forwarded_host())
        }
    }
--- request
GET /t
--- more_headers
X-Forwarded-Host: test
--- response_body
host: localhost
--- no_error_log
[error]



=== TEST 2: request.get_forwarded_host() returns host using host header with tls from last hop when not trusted
--- http_config
    server {
        listen unix:$TEST_NGINX_HTML_DIR/nginx.sock ssl;
        ssl_certificate $TEST_NGINX_CERT_DIR/test.crt;
        ssl_certificate_key $TEST_NGINX_CERT_DIR/test.key;

        location / {
            content_by_lua_block {
            }

            access_by_lua_block {
                local SDK = require "kong.sdk"
                local sdk = SDK.new()

                ngx.say("host: ", sdk.request.get_forwarded_host())
            }
        }
    }
--- config
    location = /t {
        proxy_ssl_verify off;
        proxy_pass https://unix:$TEST_NGINX_HTML_DIR/nginx.sock;
    }
--- request
GET /t
--- more_headers
X-Forwarded-Host: test
--- response_body
host: localhost
--- no_error_log
[error]



=== TEST 3: request.get_forwarded_host() returns host using server name from last hop when not trusted
--- http_config
    server {
        server_name kong;
        listen unix:$TEST_NGINX_HTML_DIR/nginx.sock;

        location / {
            content_by_lua_block {
            }

            access_by_lua_block {
                local SDK = require "kong.sdk"
                local sdk = SDK.new()

                ngx.say("host: ", sdk.request.get_forwarded_host())
            }
        }
    }
--- config
    location /t {
        proxy_set_header Host "";
        proxy_pass http://unix:$TEST_NGINX_HTML_DIR/nginx.sock;
    }
--- request
GET /t
--- more_headers
X-Forwarded-Host: test
--- response_body
host: kong
--- no_error_log
[error]



=== TEST 4: request.get_forwarded_host() returns host using request line from last hop when not trusted
--- config
    location = /t {
        access_by_lua_block {
            local SDK = require "kong.sdk"
            local sdk = SDK.new()

            ngx.say("host: ", sdk.request.get_forwarded_host())
        }
    }
--- request
GET http://test/t
--- more_headers
X-Forwarded-Host: kong
--- response_body
host: test
--- no_error_log
[error]



=== TEST 5: request.get_forwarded_host() returns host using explicit host header from last hop when not trusted
--- config
    location = /t {
        access_by_lua_block {
            local SDK = require "kong.sdk"
            local sdk = SDK.new()

            ngx.say("host: ", sdk.request.get_forwarded_host())
        }
    }
--- request
GET /t
--- more_headers
Host: kong
X-Forwarded-Host: test
--- response_body
host: kong
--- no_error_log
[error]



=== TEST 6: request.get_forwarded_host() request line overrides host header from last hop when not trusted
--- config
    location = /t {
        access_by_lua_block {
            local SDK = require "kong.sdk"
            local sdk = SDK.new()

            ngx.say("host: ", sdk.request.get_forwarded_host())
        }
    }
--- request
GET http://test/t
--- more_headers
Host: kong
X-Forwarded-Host: test
--- response_body
host: test
--- no_error_log
[error]



=== TEST 7: request.get_host() request line is normalized and taken from last hop when not trusted
--- config
    location = /t {
        access_by_lua_block {
            local SDK = require "kong.sdk"
            local sdk = SDK.new()

            ngx.say("host: ", sdk.request.get_forwarded_host())
        }
    }
--- request
GET http://TEST/t
--- more_headers
Host: kong
X-Forwarded-Host: not-trusted
--- response_body
host: test
--- no_error_log
[error]



=== TEST 8: request.get_host() explicit host header is normalized and taken from last hop when not trusted
--- config
    location = /t {
        access_by_lua_block {
            local SDK = require "kong.sdk"
            local sdk = SDK.new()

            ngx.say("host: ", sdk.request.get_forwarded_host())
        }
    }
--- request
GET /t
--- more_headers
Host: K0nG
X-Forwarded-Host: not-trusted
--- response_body
host: k0ng
--- no_error_log
[error]



=== TEST 9: request.get_host() server name is normalized and used when not trusted
--- http_config
    server {
        server_name K0nG;
        listen unix:$TEST_NGINX_HTML_DIR/nginx.sock;

        location / {
            content_by_lua_block {
            }

            access_by_lua_block {
                local SDK = require "kong.sdk"
                local sdk = SDK.new()

                ngx.say("host: ", sdk.request.get_host())
            }
        }
    }
--- config
    location /t {
        proxy_set_header Host "";
        proxy_pass http://unix:$TEST_NGINX_HTML_DIR/nginx.sock;
    }
--- request
GET /t
--- more_headers
X-Forwarded-Host: not-trusted
--- response_body
host: k0ng
--- no_error_log
[error]



=== TEST 10: request.get_forwarded_host() returns host from forwarded host header when trusted
--- config
    location = /t {
        access_by_lua_block {
            local SDK = require "kong.sdk"
            local sdk = SDK.new({
                trusted_ips = { "0.0.0.0/0", "::/0" }
            })

            ngx.say("host: ", sdk.request.get_forwarded_host())
        }
    }
--- request
GET /t
--- more_headers
X-Forwarded-Host: test
--- response_body
host: test
--- no_error_log
[error]



=== TEST 11: request.get_forwarded_host() returns host from forwarded host header with tls when trusted
--- http_config
    server {
        listen unix:$TEST_NGINX_HTML_DIR/nginx.sock ssl;
        ssl_certificate $TEST_NGINX_CERT_DIR/test.crt;
        ssl_certificate_key $TEST_NGINX_CERT_DIR/test.key;

        location / {
            content_by_lua_block {
            }

            access_by_lua_block {
                local SDK = require "kong.sdk"
                local sdk = SDK.new({
                    trusted_ips = { "0.0.0.0/0", "::/0" }
                })

                ngx.say("host: ", sdk.request.get_forwarded_host())
            }
        }
    }
--- config
    location = /t {
        proxy_ssl_verify off;
        proxy_pass https://unix:$TEST_NGINX_HTML_DIR/nginx.sock;
    }
--- request
GET /t
--- more_headers
X-Forwarded-Host: test
--- response_body
host: test
--- no_error_log
[error]



=== TEST 12: request.get_forwarded_host() forwarded host overrides request line and host header when trusted
--- config
    location = /t {
        access_by_lua_block {
            local SDK = require "kong.sdk"
            local sdk = SDK.new({
                trusted_ips = { "0.0.0.0/0", "::/0" }
            })

            ngx.say("host: ", sdk.request.get_forwarded_host())
        }
    }
--- request
GET http://demo/t
--- more_headers
Host: kong
X-Forwarded-Host: test
--- response_body
host: test
--- no_error_log
[error]



=== TEST 13: request.get_host() forwarded host header is normalized
--- config
    location = /t {
        access_by_lua_block {
            local SDK = require "kong.sdk"
            local sdk = SDK.new({
                trusted_ips = { "0.0.0.0/0", "::/0" }
            })

            ngx.say("host: ", sdk.request.get_forwarded_host())
        }
    }
--- request
GET /t
--- more_headers
Host: test
X-Forwarded-Host: K0nG
--- response_body
host: k0ng
--- no_error_log
[error]



=== TEST 14: request.get_forwarded_host() errors on non-supported phases
--- http_config
--- config
    location = /t {
        default_type 'text/test';
        access_by_lua_block {
            local SDK = require "kong.sdk"
            local sdk = SDK.new()

            local phases = {
                "set",
                "rewrite",
                "access",
                "content",
                "log",
                "header_filter",
                "body_filter",
                "timer",
                "init_worker",
                "balancer",
                "ssl_cert",
                "ssl_session_store",
                "ssl_session_fetch",
            }

            local data = {}
            local i = 0

            for _, phase in ipairs(phases) do
                ngx.get_phase = function()
                    return phase
                end

                local ok, err = pcall(sdk.request.get_forwarded_host)
                if not ok then
                    i = i + 1
                    data[i] = err
                end
            end

            ngx.say(table.concat(data, "\n"))
        }
    }
--- request
GET /t
--- error_code: 200
--- response_body
kong.request.get_forwarded_host is disabled in the context of set
kong.request.get_forwarded_host is disabled in the context of content
kong.request.get_forwarded_host is disabled in the context of timer
kong.request.get_forwarded_host is disabled in the context of init_worker
kong.request.get_forwarded_host is disabled in the context of balancer
kong.request.get_forwarded_host is disabled in the context of ssl_cert
kong.request.get_forwarded_host is disabled in the context of ssl_session_store
kong.request.get_forwarded_host is disabled in the context of ssl_session_fetch
--- no_error_log
[error]