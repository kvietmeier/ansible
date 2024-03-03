#!/bin/sh

KPORT=9092
KHOSTS=`cat $HOME/.vdbhostnames | sed '1,$s/,/:'${KPORT}',/g'`:${KPORT}

if 
	[ "$1" = "START" ]
then
	${HOME}/bin/kafka_2.13-2.6.0/bin/kafka-console-consumer.sh  --from-beginning  --bootstrap-server ${KHOSTS} --topic USER_FINANCIAL_EVENTS
else
	${HOME}/bin/kafka_2.13-2.6.0/bin/kafka-console-consumer.sh  --bootstrap-server ${KHOSTS} --topic USER_FINANCIAL_EVENTS
fi

