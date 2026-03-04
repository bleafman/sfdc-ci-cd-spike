#!/usr/bin/env bash
#
# Round-Trip Deployment Test (Scenario 5)
# =======================================
# This script proves the core premise of the POC: can we express an entire
# Salesforce org's configuration as code and reconstitute it from scratch?
#
# What it does:
#   1. Creates a brand-new scratch org (an ephemeral, disposable Salesforce instance)
#   2. Deploys ALL metadata from this Git repo to the new org
#   3. Optionally loads seed data
#   4. Verifies everything landed correctly
#
# Prerequisites:
#   - Salesforce CLI installed (sf version)
#   - Authenticated to a Dev Hub org (sf org login web --set-default-dev-hub)
#   - Run from the project root directory
#
# Usage:
#   ./scripts/setup.sh                    # Create org + deploy metadata only
#   ./scripts/setup.sh --with-seed-data   # Also load sample data after deploy
#   ./scripts/setup.sh --scratch-alias X  # Use a custom alias (default: poc-test)
#
# Flags explained:
#   --set-default          Makes this the default org for subsequent sf commands
#   --definition-file      Points to the scratch org config (edition, features, etc.)
#   --duration-days        How many days before the scratch org auto-expires (max 30)
#   --target-org           Which org to deploy to (uses the alias we just created)
#   --wait                 How many minutes to wait for the deploy to finish

set -euo pipefail

# ---------------------------------------------------------------------------
# Parse arguments
# ---------------------------------------------------------------------------
SCRATCH_ALIAS="poc-test"
WITH_SEED_DATA=false

for arg in "$@"; do
    case $arg in
        --with-seed-data)
            WITH_SEED_DATA=true
            ;;
        --scratch-alias)
            shift
            SCRATCH_ALIAS="$1"
            ;;
        --scratch-alias=*)
            SCRATCH_ALIAS="${arg#*=}"
            ;;
    esac
done

echo "============================================"
echo "  Salesforce Round-Trip Deployment Test"
echo "============================================"
echo ""
echo "Scratch org alias: $SCRATCH_ALIAS"
echo "Seed data: $WITH_SEED_DATA"
echo ""

# ---------------------------------------------------------------------------
# Step 1: Create a fresh scratch org
# ---------------------------------------------------------------------------
echo ">>> Step 1: Creating scratch org '$SCRATCH_ALIAS'..."
echo "    This creates a brand-new, empty Salesforce org based on the"
echo "    definition in config/project-scratch-def.json."
echo ""

sf org create scratch \
    --set-default \
    --definition-file config/project-scratch-def.json \
    --alias "$SCRATCH_ALIAS" \
    --duration-days 7 \
    --wait 10

echo ""
echo "    Scratch org created successfully."
echo ""

# ---------------------------------------------------------------------------
# Step 2: Deploy all metadata from the repo
# ---------------------------------------------------------------------------
echo ">>> Step 2: Deploying metadata to '$SCRATCH_ALIAS'..."
echo "    This pushes all the XML metadata files from force-app/ to the org."
echo "    It's the equivalent of 'configuring' the org via code."
echo ""

# 'sf project deploy start' is the modern replacement for the older
# 'sfdx force:source:push'. It sends metadata to the org and waits
# for the deployment to complete.
sf project deploy start \
    --target-org "$SCRATCH_ALIAS" \
    --wait 10

echo ""
echo "    Metadata deployed successfully."
echo ""

# ---------------------------------------------------------------------------
# Step 3: (Optional) Load seed data
# ---------------------------------------------------------------------------
if [ "$WITH_SEED_DATA" = true ]; then
    echo ">>> Step 3: Loading seed data..."
    echo "    Running the Anonymous Apex script that creates sample Accounts,"
    echo "    Contacts, Opportunities, and Leads."
    echo ""

    # 'sf apex run' executes Anonymous Apex — think of it like running a
    # one-off script against the database. No permanent code is deployed;
    # it just runs the DML operations and exits.
    sf apex run \
        --file scripts/apex/seed-data.apex \
        --target-org "$SCRATCH_ALIAS"

    echo ""
    echo "    Seed data loaded."
    echo ""
fi

# ---------------------------------------------------------------------------
# Step 4: Verify deployment
# ---------------------------------------------------------------------------
echo ">>> Step 4: Verifying deployment..."
echo ""

echo "--- Checking custom fields on Opportunity ---"
# The Tooling API query below asks: "what custom fields exist on the Opportunity object?"
# This is a REST API query, not a database query — it reads the org's metadata.
sf data query \
    --query "SELECT QualifiedApiName, DataType FROM FieldDefinition WHERE EntityDefinition.QualifiedApiName = 'Opportunity' AND QualifiedApiName LIKE '%__c'" \
    --use-tooling-api \
    --target-org "$SCRATCH_ALIAS" \
    --result-format table

echo ""
echo "--- Checking roles ---"
sf data query \
    --query "SELECT Name, ParentRole.Name FROM UserRole WHERE Name IN ('VP of Sales', 'Sales Manager', 'SDR')" \
    --target-org "$SCRATCH_ALIAS" \
    --result-format table

echo ""
echo "--- Checking active Flows ---"
sf data query \
    --query "SELECT FullName, ActiveVersionId FROM FlowDefinition WHERE DeveloperName = 'Lead_Conversion_Task_Creation'" \
    --use-tooling-api \
    --target-org "$SCRATCH_ALIAS" \
    --result-format table

echo ""
echo "============================================"
echo "  Round-trip deployment test COMPLETE"
echo "============================================"
echo ""
echo "To open the scratch org in your browser:"
echo "  sf org open --target-org $SCRATCH_ALIAS"
echo ""
echo "To delete the scratch org when done:"
echo "  sf org delete scratch --target-org $SCRATCH_ALIAS --no-prompt"
