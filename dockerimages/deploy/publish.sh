rsync --delete --exclude .git --exclude CNAME -r /drone/src/docs/public /tmp/export

cd /tmp/export/public
echo "infomark.org" > CNAME
git init
git remote add origin git@github:infomark-org/infomark.git
git config --global user.name "infomark-deploy-bot"
git config --global user.email "no-reply@infomark.informatik.uni-tuebingen.de"
git status --porcelain
git add .
git commit -m "commit update"
git push -f origin HEAD:gh-pages