#!/bin/bash

# Pod 번호 리스트
#pod_numbers=("101" "102" "103" "201" "202" "203")
pod_numbers=("204")

# 원본 YAML 파일 이름
original_yaml="pod.yaml"

# 임시 YAML 파일 이름
temp_yaml="temp_pod.yaml"

# Pod을 순차적으로 생성
for number in "${pod_numbers[@]}"; do
	# 임시 YAML 파일 생성
	cp "$original_yaml" "$temp_yaml"

	      # 101를 해당 번호로 바꾸기
	      sed -i "s/101/$number/g" "$temp_yaml"

		  # Pod 생성
		  kubectl apply -f "$temp_yaml"

		      # 잠시 대기 (필요한 경우 조정 가능)
		      sleep 2
	      done

		# 임시 파일 삭제
		rm "$temp_yaml"

		echo "모든 Pod가 성공적으로 생성되었습니다."

