from mitmproxy import ctx
from mitmproxy.certs import Certificate

def tls_start_client(data):
    # This hook triggers during the handshake
    # We log it to verify the interception is happening
    ctx.log.info(f"Interception active for SNI: {data.client_hello.sni}")
