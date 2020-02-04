#!/usr/bin/env bash

cd /vagrant/templates/
pip3 install -r requirements.txt
echo "Updating Grafana Config"
./apply_templates.py --type GRAFANA_CONFIG && cp -f grafana.ini /etc/grafana/grafana.ini
echo "Updating Menu Items"
./apply_templates.py --type MENUS
echo "Updating Footer on Dashboards"
./apply_templates.py --type FOOTER_UPDATES
echo "Updating Query on Dashboards"
./apply_templates.py --type QUERY_OVERRIDE

#Install wizzy
cd /vagrant
npm install -g wizzy@0.6.0

### Start plugin installs ###
cd /vagrant/plugins

#install carpetplot
/usr/sbin/grafana-cli plugins install petrslavotinek-carpetplot-panel

## BEGIN PLUGIN INSTALL ##

#install tsds datasource plugin
cd tsds-grafana
npm install -g yarn #make seems to need this
make rpm
yum install -y $HOME/rpmbuild/RPMS/noarch/globalnoc-tsds-datasource-*.noarch.rpm
cd ../

#Install network panel plugin
cd globalnoc-networkmap-panel
npm install -g gulp #make seems to need this
make rpm
yum install -y $HOME/rpmbuild/RPMS/noarch/grnoc-grafana-worldview-*.noarch.rpm
cd ../

#Install netsage-sankey plugin
# HACK: for some reason this fails to install unless it's moved to a different location.
cp -r netsage-sankey-plugin /tmp
pushd . 
cd /tmp/netsage-sankey-plugin
make install
popd

#Install navigation
# HACK: for some reason this fails to install unless it's moved to a different location.
cp -r  NetSageNavigation /tmp/
pushd . 
cd /tmp/NetSageNavigation/
make install
popd
### End plugin source code installs ###


#Install navigation
# HACK: for some reason this fails to install unless it's moved to a different location.
cp -r  Netsage-Slope_graph /tmp/
pushd . 
cd /tmp/Netsage-Slope_graph/
make install
popd
### End plugin source code installs ###



## END PLUGIN INSTALL ##


#Enable grafana
systemctl enable grafana-server
systemctl restart grafana-server

#Set to local context
cd /vagrant
cp -f conf/wizzy.json.default conf/wizzy.json

wizzy set context grafana local #this should be the default, but just in case
wizzy export dashboards
wizzy export datasources

##
# This is how the github repo was built
#wizzy init
#wizzy set grafana url https://portal.netsage.global/grafana/

##
# Point at local grafana instance for easy deployment
#wizzy set grafana url http://localhost:3000
#wizzy set grafana username admin
#wizzy set grafana password admin
