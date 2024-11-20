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
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update
#diplay latest version
helm search repo ingress-nginx/ingress-nginx
#diplay history 
helm search repo -l ingress-nginx/ingress-nginx
helm pull ingress-nginx/ingress-nginx --version=4.7.0  --untar 

mv -f $currdir/*  ../$currdir
rm -r $currdir
