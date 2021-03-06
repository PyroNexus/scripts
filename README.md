# Helper scripts to run a Stakepool node

**stuck_check.sh** - Will restart node when a "stuck_notifier" is thrown\
                 In node-config you can define the time threshold when you want the node to throw the stuck_notifier\
                 E.g. "no_blockchain_updates_warning_interval: 5m" (default is 30m)
                 Assumption: systemctl is used to start jormungandr node.\
                 Replace all <> placeholders to match your setup.
                 
**pooltool.sh** - Simple wrapper to call sendmytip in regular intervals while sending only the tip of the leader node when running multiple nodes (assumption 2). For this to work set RESTAPI_PORT=$1 in sendmytip.sh to accept the port parameter from this wrapper                
            
**updatepeers.sh** - Based on the start-node.sh script from agent-rat. Will rewrite a node-config.json input file based on tcpping results. Only open peers are written to the config-runtime.\
               If you have a JAML file currently, you can use a converter such as https://codebeautify.org/yaml-to-json-xml-csv? to convert the JAML to json\
              Use https://jsonlint.com/ to verifty the soure JSON file is correct\
              Only keep the peers in the source file you are interested in (e.g. the fastest peers)\
              Modify InitVar section to your local environment
              
**jormon.sh** - Based on the more aggressive restart script from Michael Fazio (sandstone.io)\
            With a twist: This update now also considers a node stuck if it is too long offline or in bootstrap mode.\
            Additional features: Improved logging.\
            Assumption: systemctl is used to start jormungandr node\
            Replace all <> placeholders to match your setup\
            Known issues: If timing is unlucky and no new block is received between bootstrap end and next polling after a restart, the bootstrap time will be added to the already overflown time intervall and another restart will the triggered potentially causing a restart loop
