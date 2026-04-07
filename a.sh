#!/bin/bash
# publish-all-tags.sh

export JAVA_HOME=/opt/homebrew/opt/openjdk@17
export PATH=$JAVA_HOME/bin:$PATH

TAGS="v1.0.0 v1.1.0 v1.2.0 v1.2.1 v1.3.0 v1.4.0 v1.4.1 v1.4.2 v1.4.2-rc1"
FAILED_TAGS=()
SKIPPED_TAGS=()

for tag in $TAGS; do
    echo "Publishing $tag with Java 17..."
    git checkout $tag
    
    if [ $? -ne 0 ]; then
        FAILED_TAGS+=("$tag (checkout failed)")
        continue
    fi
    
    # Tenta publicar
    mvn clean deploy -DskipTests \
        -DaltDeploymentRepository=github::https://maven.pkg.github.com/maltzsama/spark-sql-kinesis-connector
    
    EXIT_CODE=$?
    
    if [ $EXIT_CODE -eq 0 ]; then
        echo "Successfully published $tag"
    elif [ $EXIT_CODE -eq 1 ] && [ "$(echo "$output" | grep '409')" != "" ]; then
        echo "Version already exists for $tag, skipping..."
        SKIPPED_TAGS+=("$tag (already exists)")
    else
        echo "Failed to publish $tag"
        FAILED_TAGS+=("$tag (publish failed)")
    fi
done

git checkout main

echo ""
echo "========================================="
echo "SUMMARY"
echo "========================================="
echo "✅ Published: success"
echo "⏭️  Skipped (already exists): ${#SKIPPED_TAGS[@]}"
for skipped in "${SKIPPED_TAGS[@]}"; do
    echo "   - $skipped"
done
echo "❌ Failed: ${#FAILED_TAGS[@]}"
for failed in "${FAILED_TAGS[@]}"; do
    echo "   - $failed"
done