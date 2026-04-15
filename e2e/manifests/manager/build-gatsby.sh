#!/bin/bash -ex
cd $HOME
rm -rf $REPO_NAME
git clone $REPO_URL
cd $REPO_NAME
git checkout $REVISION

# Because pnpm 10.12.1 used in Gatsby init builds does not support --allow-build=sharp, 
# the build fails; we fix this by generating a temporary pnpm-workspace.yaml in the Gatsby repo and allowlisting sharp via onlyBuiltDependencies.
cat > pnpm-workspace.yaml <<'EOF'
onlyBuiltDependencies:
  - sharp
EOF

pnpm install --lockfile-only
pnpm install --frozen-lockfile
pnpm run build

rm -rf $OUTPUT/*
cp -r public/* $OUTPUT/
