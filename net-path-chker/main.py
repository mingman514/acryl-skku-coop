from utils import *
from switch_parser import *
import time, datetime
import logging, argparse

INTERVAL = 0  # in seconds
TARGET_PORT = [1,2,3,4]  # SPINE: [1,2,9,10]  LEAF: [1,2,3,4]

# 서버 정보 및 로그인 정보 설정
servers = [
    # {'name': 'ACRSPINE-001', 'ip': '115.71.36.62', 'username': 'admin', 'password': 'comnet02', 'session': None},
    # {'name': 'ACRSPINE-002', 'ip': '115.71.36.61', 'username': 'admin', 'password': 'comnet02', 'session': None},
    # {'name': 'ACRLEAF-001', 'ip': '115.71.36.60', 'username': 'admin', 'password': 'comnet02', 'session': None}
    {'name': 'ACRLEAF-002', 'ip': '115.71.36.59', 'username': 'admin', 'password': 'comnet02', 'session': None}
]

def calc_tput(cur, prev, step_t):
    return str(round((int(cur) - int(prev)) / (step_t * 125000000), 2))

def print_and_logging(text, logEnable):
    print(text)
    if logEnable:
        logging.info(text)

def main():
    parser = argparse.ArgumentParser(description='Network Path Checker (NPC)')
    parser.add_argument('-l', '--log', action='store_true', help='로그 파일 생성 여부')
    args = parser.parse_args()

    initialize(servers)

    # Logging
    if args.log:
        logging.getLogger().setLevel(logging.INFO)
        logging.basicConfig(filename=f'log_{time.strftime("%Y%m%d%H%M%S")}.txt', encoding='utf-8')

    prev_data = []
    prev_time = None
    start_time = datetime.datetime.now()

    print_and_logging(f"Monitoring: [{servers[0]['name']}] (Unit: Gb/s)\nTime(s)\tRx_P1\tRx_P2\tRx_P3\tRx_P4\tP_Cnt\tTx_P1\tTx_P2\tTx_P3\tTx_P4\tP_Cnt", args.log)
    while True:
        p_data = []

        leaf_1_data = commands(servers[0], ["show interfaces ethernet 1/1-1/16 counters roce", "show clock"])
        switch_time = parse_switch_time(leaf_1_data[1])
        for idx in TARGET_PORT:
            p_data.append(parse_rx_tx(leaf_1_data[0]['data'], idx))
        # print(p_data)

        if prev_time is not None:
            # 앱 실행시간 체크
            end_time = datetime.datetime.now()
            elapsed_time = end_time - start_time
            elapsed_seconds = round(elapsed_time.total_seconds(), 1)
            
            # 스위치 기준 경과 시간 확인
            step_time = switch_time - prev_time
            # 시간 차가 음수인 경우
            if step_time.total_seconds() < 0:
                step_time += datetime.timedelta(days=1)

            result = f'{str(elapsed_seconds)}'
            for x in range(2):
                p_cnt = 0
                for y in range(len(TARGET_PORT)):
                    tput = calc_tput(p_data[y][x], prev_data[y][x], float(step_time.total_seconds()))
                    if float(tput) > 0:
                        p_cnt += 1
                    result += f"\t{tput}"
                result += f"\t{p_cnt}"
            print_and_logging(result, args.log)
            
        prev_time = switch_time
        prev_data = p_data
        time.sleep(INTERVAL)

if __name__ == "__main__":
    main()