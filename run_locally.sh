#!/bin/bash

memtier_instances=1
memtier_threads=2
memtier_clients_pt=5
test_time=50

memcached_ip="127.0.0.1"
memcached_ports=(8080 8081 8082)

middleware_ip="127.0.0.1"
middleware_ports=(5555)
middleware_workers=64

SET_ratio=10
GET_ratio=10

jar_file_name="dist/middleware-nikolijo.jar"
current_json_output_file="json_output.json"

start_memcached() {
	echo "	Starting memcached.."
	for memcached_port in "${memcached_ports[@]}"
	do
		memcached -t 1 -p $memcached_port &
		echo "	Memcached started on ip "$memcached_ip" and on port "$memcached_port
		sleep 0.5
	done	
}

start_middleware() {
	echo "	Starting middleware.."
	for middleware_port in "${middleware_ports[@]}"
	do
		java -jar $jar_file_name -l $middleware_ip -p $middleware_port -m "$memcached_ip:${memcached_ports[0]}" "$memcached_ip:${memcached_ports[1]}" "$memcached_ip:${memcached_ports[2]}" -t $middleware_workers -s true &
		echo "	Middleware started with following parameters:"
		echo "		 ip address = "$middleware_ip", port = "$middleware_port
		echo "		 number of workers = "$middleware_workers
		echo "		 sharded reading = true"
		sleep 1
	done	
}

start_memtier() {
	echo "	Starting memtier(s).."
	for memtier_vm in `seq 1 1 $memtier_instances`
	do
		z=$(($memtier_vm-1))
		command_for_memtier=" ./memtier_benchmark-master/memtier_benchmark --server="$middleware_ip" \
									  --port="${middleware_ports[0]}" \
									  --protocol=memcache_text \
									  --expiry-range=9999-10000 \
									  --key-maximum=10000 --data-size=1024 \
									  --random-data \
									  --clients="$memtier_clients_pt" \
									  --threads="$memtier_threads" \
									  --test-time="$test_time" \
									  --ratio="$SET_ratio":"$GET_ratio" \
									  --multi-key-get=3 \
									  --json-out-file="$current_json_output_file" "

		if [ $memtier_vm -lt 1 ]
			then
				echo "RUNNING 1ST ONE ^^^^^^^^^"
				nohup "${command_for_memtier}" &>/dev/null &
		else
			echo "RUNNING 2ND ONE **********"
			$command_for_memtier
		fi
	done
}

kill_middleware() {
	echo "	Killing middleware.."
	for middleware_port in "${middleware_ports[@]}"
	do
		kill $(ps -ef | grep "nikolijo" | head -1 | awk -F " " '{print $2}')
	done
}

kill_memcached() {
	echo "	Killing middleware.."
	for memcached_port in "${memcached_ports[@]}"
	do
		lsof -t -i:$memcached_port | xargs kill -9
	done
}

kill_basic_memcached() {
	sudo service memcached stop
}

run() {
	echo "Starting experiment.."

	rm -r build/ logs/ dist/ json* dstat*
	ant -f build.xml

	# kill_basic_memcached
	kill_memcached

	start_memcached

	sleep 5

	start_middleware

	sleep 5

	nohup dstat -c -d -i -l -m -n -p -t --tcp  --top-cpu-adv --top-latency --top-mem --output dstat_output1.csv &>/dev/null &

	SET_ratio=1
	GET_ratio=0
	start_memtier

	SET_ratio=1
	GET_ratio=9
	
	echo "	Starting memtier(s).."
	for memtier_vm in `seq 1 1 $memtier_instances`
	do
		z=$(($memtier_vm-1))
		command_for_memtier=" ./memtier_benchmark-master/memtier_benchmark --server="$middleware_ip" \
									  --port="${middleware_ports[0]}" \
									  --protocol=memcache_text \
									  --expiry-range=9999-10000 \
									  --key-maximum=10000 --data-size=1024 \
									  --random-data \
									  --clients="$memtier_clients_pt" \
									  --threads="$memtier_threads" \
									  --test-time=90 \
									  --ratio=1:9 \
									  --multi-key-get=9 \
									  --json-out-file="$current_json_output_file" "

		if [ $memtier_vm -lt 1 ]
			then
				echo "RUNNING 1ST ONE ^^^^^^^^^"
				nohup "${command_for_memtier}" &>/dev/null &
		else
			echo "RUNNING 2ND ONE **********"
			$command_for_memtier
		fi
	done

	pkill dstat

	kill_middleware

	kill_memcached
}

run