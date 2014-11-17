export TOSHI_NETWORK=regtest NODE_ACCEPT_INCOMING=true NODE_LISTEN_PORT=18444 JAVA_HOME=/usr/lib/jvm/java-7-openjdk-amd64

foreman start -c web=0,block_worker=1,transaction_worker=1,peer_manager=1 1>foreman.log 2>foreman.log &

java -Xms64m -Xmx512m -jar spec/regtest/test-scripts/BitcoindComparisonTool_jar/BitcoindComparisonTool.jar 1>>log/regtest.log 2>>log/regtest.log &
