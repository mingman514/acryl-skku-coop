import requests, sys
import time

def login_and_get_session(server_info):
    with requests.Session() as session:
        login_response = session.post(f'http://{server_info["ip"]}/admin/launch?script=rh&template=login&action=login', data={'f_user_id': server_info['username'], 'f_password': server_info['password']})
        # 로그인 성공 여부 확인
        if login_response.ok:
            return session
        else:
            print(f"로그인 실패: {login_response.status_code} (server: {server_info['name']})")
            sys.exit()

def command_to_switch(server_info, cmd):
        response = server_info['session'].post(f'http://{server_info["ip"]}/admin/launch?script=json', json={"cmd": cmd})
        # 요청 성공 여부 확인
        if response.ok:
            # JSON 데이터 파싱
            return response.json()['data']
        else:
            print(f"데이터 요청 실패: {response.status_code}  (server: {server_info['name']})")
            return 'err'