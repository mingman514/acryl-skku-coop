# Parser for switch
import datetime

def parse_switch_time(res):
    t = res['data']['Time']
    return datetime.datetime.strptime(t, "%H:%M:%S")

# idx는 실제 포트번호와 마찬가지로 1부터 시작
def parse_field(data, idx, dir, field):
    eth_port = list(data[idx-1].keys())[0]
    fields = data[idx-1][eth_port][0]['Rx'][0] if dir == 'rx' else data[idx-1][eth_port][1]['Tx'][0]
    return fields[field]

def parse_rx_tx(data, idx):
    Rx_bytes = parse_field(data, idx, 'rx', 'RoCE PG bytes')
    Tx_bytes = parse_field(data, idx, 'tx', 'RoCE TC bytes')
    return (Rx_bytes, Tx_bytes)