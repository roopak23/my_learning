currdir=`basename "$PWD"`

mkdir ../tmp_$currdir
##buckup custom files
cp values-dm3.yaml  ../tmp_$currdir/
cp pull.sh  ../tmp_$currdir/
# clean folder
rm -r *

##restore custom files
cp -r ../tmp_$currdir/* .

#delete backup folder
rm -r ../tmp_$currdir

## pull chart 
helm repo add airflow-stable https://airflow-helm.github.io/charts
helm repo update
#diplay latest version
helm search repo airflow-stable/airflow
#diplay history 
helm search repo -l airflow-stable/airflow
helm pull  airflow-stable/airflow --version=8.7.1 --untar 

mv -f $currdir/*  ../$currdir
rm -r $currdir