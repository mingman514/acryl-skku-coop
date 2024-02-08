from utils import login_and_get_session, command_to_switch
import time
import pandas as pd

INTERVAL = 2  # in seconds

# 서버 정보 및 로그인 정보 설정
servers = [
    {'name': 'ACRSPINE-001', 'ip': '115.71.36.62', 'username': 'admin', 'password': 'comnet02', 'session': None},
    {'name': 'ACRSPINE-002', 'ip': '115.71.36.61', 'username': 'admin', 'password': 'comnet02', 'session': None}
    # {'name': 'ACRLEAF-001', 'ip': '115.71.36.60', 'username': 'admin', 'password': 'comnet02', 'session': None},
    # {'name': 'ACRLEAF-002', 'ip': '115.71.36.59', 'username': 'admin', 'password': 'comnet02', 'session': None}
]

def command(server, cmd):
    data = command_to_switch(server, cmd)
    if data == 'err':
        print('3초 후 세션 업데이트 시도 및 요청 재시도')
        time.sleep(3)

        update_session(server)
        command(server, cmd)
    return data

def update_session(server):
    server['session'] = login_and_get_session(server)

def update_session_all():
    print('update all sesions')
    for server in servers:
        server['session'] = login_and_get_session(server)

def clear_counters_all():
    print('clear all counters')
    for server in servers:
        command(server, "clear counters all")

def initialize():
    update_session_all()
    clear_counters_all()
    print('initialize done')


initialize()

# idx는 실제 포트번호와 마찬가지로 1부터 시작
def parse_field(data, idx, dir, field):
    eth_port = list(data[idx-1].keys())[0]
    fields = data[idx-1][eth_port][0]['Rx'][0] if dir == 'rx' else data[idx-1][eth_port][1]['Tx'][0]
    return fields[field]

def parse_rx_tx(data, idx):
    Rx_pkt = parse_field(data, idx, 'rx', 'RoCE PG packets')
    Rx_bytes = parse_field(data, idx, 'rx', 'RoCE PG bytes')
    Tx_pkt = parse_field(data, idx, 'tx', 'RoCE TC packets')
    Tx_bytes = parse_field(data, idx, 'tx', 'RoCE TC bytes')
    return (Rx_pkt, Rx_bytes, Tx_pkt, Tx_bytes)

def byte_to_MB(num):
    return round(float(num) / 1024 / 1024)

while True:
    # 데이터 생성
    p_data = {
        'Rx pkt': [],
        'Rx MB': [],
        'Tx pkt': [],
        'Tx MB': []
    }

    spine_1_data = command(servers[0], "show interfaces ethernet 1/1-1/16 counters roce")
    spine_2_data = command(servers[1], "show interfaces ethernet 1/1-1/16 counters roce")

    # 1~4는 spine_1_data, 5~8은 spine_2_data
    for data in [spine_1_data, spine_2_data]:
        for idx in [1,2,9,10]:
            res = parse_rx_tx(data, idx)
            p_data['Rx pkt'].append(res[0])
            p_data['Rx MB'].append(byte_to_MB(res[1]))
            p_data['Tx pkt'].append(res[2])
            p_data['Tx MB'].append(byte_to_MB(res[3]))

    # 행 인덱스 설정
    index = ['P' + str(i+1) for i in range(8)]

    # DataFrame 생성
    df = pd.DataFrame(p_data, index=index)

    # DataFrame 출력
    print('-------------------------------------------------------')
    print(df)

    time.sleep(INTERVAL)