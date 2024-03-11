from switch import login_and_get_session, command_to_switch, commands_to_switch
import time

def command(server, cmd):
    data = command_to_switch(server, cmd)
    if data == 'err':
        print('3초 후 세션 업데이트 시도 및 요청 재시도')
        time.sleep(3)
        update_session(server)
        command(server, cmd)
    return data

def commands(server, cmd):
    data = commands_to_switch(server, cmd)
    if data == 'err':
        print('3초 후 세션 업데이트 시도 및 요청 재시도')
        time.sleep(3)
        update_session(server)
        commands(server, cmd)
    return data

def update_session(server):
    server['session'] = login_and_get_session(server)

def update_session_all(server_list):
    print('update all sesions')
    for server in server_list:
        server['session'] = login_and_get_session(server)

def clear_counters_all(server_list):
    print('clear all counters')
    for server in server_list:
        command(server, "clear counters all")

def initialize(server_list):
    update_session_all(server_list)
    clear_counters_all(server_list)
    print('initialize done\n')