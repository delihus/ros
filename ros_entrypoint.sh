#!/bin/bash
set -e

case $DDS_CONFIG in
    'HUSARNET_SIMPLE_AUTO')
        if [ $RMW_IMPLEMENTATION == 'rmw_fastrtps_cpp' ]; then
            DDS_CONFIG_OUTPUT=/dds-husarnet-simple-auto-fastdds.xml
            export FASTRTPS_DEFAULT_PROFILES_FILE=$DDS_CONFIG_OUTPUT

            /gen-xml-simple-fastdds.sh \
                /dds-config-templates/fastdds-simple.xml \
                $FASTRTPS_DEFAULT_PROFILES_FILE

            sed '/FASTRTPS_DEFAULT_PROFILES_FILE/d' -i /etc/bash.bashrc
            echo "export FASTRTPS_DEFAULT_PROFILES_FILE=file://$DDS_CONFIG_OUTPUT" >> /etc/bash.bashrc

        elif [ $RMW_IMPLEMENTATION == 'rmw_cyclonedds_cpp' ]; then
            DDS_CONFIG_OUTPUT=/dds-husarnet-simple-auto-cyclonedds.xml
            export CYCLONEDDS_URI=file://$DDS_CONFIG_OUTPUT

            /gen-xml-simple-cyclonedds.sh \
                /dds-config-templates/cyclonedds-simple.xml \
                $DDS_CONFIG_OUTPUT

            sed '/CYCLONEDDS_URI/d' -i /etc/bash.bashrc
            echo "export CYCLONEDDS_URI=file://$DDS_CONFIG_OUTPUT" >> /etc/bash.bashrc
        fi
        ;;

    'HUSARNET_DISCOVERY_SERVER')
        export RMW_IMPLEMENTATION=rmw_fastrtps_cpp
        export FASTRTPS_DEFAULT_PROFILES_FILE=/dds-husarnet-ds.xml

        export HOST_IPV6=$(ifconfig hnet0 | grep 'inet6 .* prefixlen 16' | sed -r 's/\s*inet6 ([a-f0-9:]*)\s\sprefixlen 16.*/\1/g')

        if [[ -z $ROS_DISCOVERY_SERVER ]]; then
            # server config
            cat /fastdds-ds-server-template.xml | envsubst > $FASTRTPS_DEFAULT_PROFILES_FILE
        else
            # client config
            export DISCOVERY_SERVER_IPV6=$(cat /etc/hosts | grep $ROS_DISCOVERY_SERVER | sed -r 's/([a-f0-9:]*)\s(.*)\s# managed by Husarnet/\1/g')
            cat /fastdds-ds-client-template.xml | envsubst > $FASTRTPS_DEFAULT_PROFILES_FILE
        fi
        ;;

    'ENVSUBST')
        if [ $RMW_IMPLEMENTATION == 'rmw_fastrtps_cpp' ]; then
            if [[ -n $FASTRTPS_DEFAULT_PROFILES_FILE ]]; then
                AUXFILE="/dds-config-aux.xml"
                cp --attributes-only --preserve $FASTRTPS_DEFAULT_PROFILES_FILE $AUXFILE
                cat $FASTRTPS_DEFAULT_PROFILES_FILE | envsubst > $AUXFILE
                export FASTRTPS_DEFAULT_PROFILES_FILE=$AUXFILE

                sed '/FASTRTPS_DEFAULT_PROFILES_FILE/d' -i /etc/bash.bashrc
                echo "export FASTRTPS_DEFAULT_PROFILES_FILE=file://$AUXFILE" >> /etc/bash.bashrc
            fi
        elif [ $RMW_IMPLEMENTATION == 'rmw_cyclonedds_cpp' ]; then
            if [[ -n $CYCLONEDDS_URI ]]; then
                DDS_CONFIG_OUTPUT=$(echo $CYCLONEDDS_URI | sed -r 's/file:\/\/(.*)/\1/g')
                AUXFILE="/dds-config-aux.xml"
                cp --attributes-only --preserve $DDS_CONFIG_OUTPUT $AUXFILE
                cat $DDS_CONFIG_OUTPUT | envsubst > $AUXFILE
                export CYCLONEDDS_URI=file://$AUXFILE

                sed '/CYCLONEDDS_URI/d' -i /etc/bash.bashrc
                echo "export CYCLONEDDS_URI=file://$AUXFILE" >> /etc/bash.bashrc
            fi
        fi
        ;;
esac

# setup ros environment
source "/opt/ros/$ROS_DISTRO/setup.bash"
test -f "/ros2_ws/install/setup.bash" && source "/ros2_ws/install/setup.bash"

exec "$@"