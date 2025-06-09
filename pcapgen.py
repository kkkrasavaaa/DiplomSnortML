from scapy.all import *

# IP та порти клієнта і сервера
client_ip = "172.16.10.102"
server_ip = "172.16.10.120"
server_port = 80
client_port = 41297

# 1. SYN (Клієнт -> Сервер)
syn = IP(src=client_ip, dst=server_ip) / TCP(sport=client_port, dport=server_port, flags='S', seq=1000)
# 2. SYN-ACK (Сервер -> Клієнт)
syn_ack = IP(src=server_ip, dst=client_ip) / TCP(sport=server_port, dport=client_port, flags='SA', seq=2000, ack=syn.seq + 1)
# 3. ACK (Клієнт -> Сервер)
ack = IP(src=client_ip, dst=server_ip) / TCP(sport=client_port, dport=server_port, flags='A', seq=syn.seq + 1, ack=syn_ack.seq + 1)

# 4. HTTP GET із SQL-ін'єкцією (Клієнт -> Сервер)
http_get = IP(src=client_ip, dst=server_ip) / TCP(sport=client_port, dport=server_port, flags='PA', seq=syn.seq + 1, ack=syn_ack.seq + 1) / \
    "GET /php/admin_notification.php?foo=1%27%20OR%202=3%2D%2D-- HTTP/1.1\r\nHost: 172.16.10.120\r\n\r\n"

# 5. HTTP-відповідь (Сервер -> Клієнт) - вигадана
http_response = IP(src=server_ip, dst=client_ip) / TCP(sport=server_port, dport=client_port, flags='PA', seq=syn_ack.seq + 1, ack=syn.seq + len(http_get[Raw]), window=1026) / \
    "HTTP/1.1 200 OK\r\nContent-Type: text/html\r\nContent-Length: 13\r\n\r\nHello, World!"

# 6. FIN-ACK (Клієнт -> Сервер)
fin = IP(src=client_ip, dst=server_ip) / TCP(sport=client_port, dport=server_port, flags='FA', seq=syn.seq + len(http_get[Raw]), ack=syn_ack.seq + len(http_response[Raw]))

# 7. FIN-ACK Відповідь (Сервер -> Клієнт)
fin_ack = IP(src=server_ip, dst=client_ip) / TCP(sport=server_port, dport=client_port, flags='FA', seq=syn_ack.seq + len(http_response[Raw]), ack=fin.seq + 1)

# 8. Останній ACK (Клієнт -> Сервер)
final_ack = IP(src=client_ip, dst=server_ip) / TCP(sport=client_port, dport=server_port, flags='A', seq=fin.seq + 1, ack=fin_ack.seq + 1)

# Зберегти пакети у файл pcap
wrpcap("simulated_sql_injection.pcap", [syn, syn_ack, ack, http_get, http_response, fin, fin_ack, final_ack])

print("Файл pcap успішно згенеровано як 'simulated_sql_injection.pcap'")