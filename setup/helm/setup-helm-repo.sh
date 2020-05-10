#/bin/bash
set -e
set -u
set -o xtrace

git clone florianseidel/DevOps_Capstone_Repo
cd DevOps_Capstone_Repo
touch README.md
git add README.md
git commit -m "Initial commit"
git push

echo "Now go and enable GitHub Pages in the repository settings on GitHub."

helm repo add DevOps_Capstone_Repo https://florianseidel.github.io/DevOps_Capstone_Repo/