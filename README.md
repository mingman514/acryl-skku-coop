# acryl-skku-coop

## Requirements
(모든 노드)
- Nvidia driver 및 Mellanox driver 설치

## Install
1. Initial Setting - 최초 한 번만 실행
(모든 노드)
```
./initial_setting.sh
```

2. kube_init.sh의 TARGET_IP에 RNIC IP 입력 (마스터 노드만)
ex. 10.0.104.2
3. Kube Init (마스터 노드만)
```
./kube_init.sh
```

4. (Optional) 워커노드 연결
- kube_init.sh 실행중 "kubeadm join ..." 명령어를 워커노드에서 실행

5. 실행 결과 확인
```
kubectl get all -A
```
