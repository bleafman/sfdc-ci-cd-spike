#!/usr/bin/env bash
#
# Round-Trip Deployment Test (Scenario 5)
# =======================================
# This script proves the core premise of the spike: can we express an entire
# Salesforce org's configuration as code and reconstitute it from scratch?
#
# What it does:
#   1. Creates a brand-new scratch org (an ephemeral, disposable Salesforce instance)
#   2. Installs managed packages from dependencies.json
#   3. Creates roles via Apex (role metadata deploys are brittle — see LEARNINGS.md)
#   4. Deploys ALL metadata from this Git repo to the new org
#   5. Grants FLS to System Administrator (deploy doesn't do this automatically)
#   6. Optionally loads seed data
#   7. Verifies everything landed correctly
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

sf org create scratch \
    --set-default \
    --definition-file config/project-scratch-def.json \
    --alias "$SCRATCH_ALIAS" \
    --duration-days 7 \
    --wait 10

echo ""
echo "    Scratch org created."
echo ""

# ---------------------------------------------------------------------------
# Step 2: Install managed packages from dependencies.json
# ---------------------------------------------------------------------------
# Managed package metadata can't be deployed via source deploy — it must be
# installed via `sf package install`. This step reads our dependency manifest
# and installs each package before deploying our source (which may reference
# namespaced objects/fields from these packages).
echo ">>> Step 2: Installing managed packages..."

DEPS_FILE="dependencies.json"
if [ -f "$DEPS_FILE" ]; then
    PACKAGE_COUNT=$(jq '.packages | length' "$DEPS_FILE")
    for ((i=0; i<PACKAGE_COUNT; i++)); do
        PKG_NAME=$(jq -r ".packages[$i].name" "$DEPS_FILE")
        PKG_VERSION=$(jq -r ".packages[$i].versionId" "$DEPS_FILE")
        PKG_REQUIRED=$(jq -r ".packages[$i].required" "$DEPS_FILE")

        echo "    Installing $PKG_NAME ($PKG_VERSION)..."
        if ! sf package install \
            --package "$PKG_VERSION" \
            --target-org "$SCRATCH_ALIAS" \
            --wait 15 \
            --no-prompt; then
            if [ "$PKG_REQUIRED" = "true" ]; then
                echo "    ERROR: Required package $PKG_NAME failed to install. Aborting."
                exit 1
            else
                echo "    WARNING: Optional package $PKG_NAME failed to install. Continuing."
            fi
        fi
    done
    echo ""
    echo "    Packages installed."
else
    echo "    No dependencies.json found. Skipping package installation."
fi
echo ""

# ---------------------------------------------------------------------------
# Step 3: Create roles via Apex
# ---------------------------------------------------------------------------
# Role metadata deployment is brittle (element ordering, access level values,
# description length limits, unhelpful error messages). Creating via Apex is
# more reliable. See LEARNINGS.md for details.
echo ">>> Step 3: Creating roles via Apex..."

sf apex run \
    --file scripts/apex/create-roles.apex \
    --target-org "$SCRATCH_ALIAS"

echo ""
echo "    Roles created."
echo ""

# ---------------------------------------------------------------------------
# Step 4: Deploy all metadata from the repo
# ---------------------------------------------------------------------------
echo ">>> Step 4: Deploying metadata to '$SCRATCH_ALIAS'..."

sf project deploy start \
    --target-org "$SCRATCH_ALIAS" \
    --ignore-conflicts \
    --wait 10

echo ""
echo "    Metadata deployed."
echo ""

# ---------------------------------------------------------------------------
# Step 5: Grant FLS to System Administrator
# ---------------------------------------------------------------------------
# Deploying custom fields does NOT automatically grant field-level security
# to the System Administrator profile. Without this step, Apex scripts
# (including seed data) can't access the custom fields.
echo ">>> Step 5: Granting FLS to System Administrator..."

sf apex run \
    --file scripts/apex/grant-admin-fls.apex \
    --target-org "$SCRATCH_ALIAS"

echo ""
echo "    FLS granted."
echo ""

# ---------------------------------------------------------------------------
# Step 6: (Optional) Load seed data
# ---------------------------------------------------------------------------
if [ "$WITH_SEED_DATA" = true ]; then
    echo ">>> Step 6: Loading seed data..."

    sf apex run \
        --file scripts/apex/seed-data.apex \
        --target-org "$SCRATCH_ALIAS"

    echo ""
    echo "    Seed data loaded."
    echo ""
fi

# ---------------------------------------------------------------------------
# Step 7: Verify deployment
# ---------------------------------------------------------------------------
echo ">>> Step 7: Verifying deployment..."
echo ""

echo "--- Custom fields on Opportunity ---"
sf data query \
    --query "SELECT QualifiedApiName, DataType FROM FieldDefinition WHERE EntityDefinition.QualifiedApiName = 'Opportunity' AND QualifiedApiName LIKE '%__c'" \
    --use-tooling-api \
    --target-org "$SCRATCH_ALIAS" \
    --result-format human

echo ""
echo "--- Roles ---"
sf data query \
    --query "SELECT Name, ParentRole.Name FROM UserRole WHERE Name IN ('VP of Sales', 'Sales Manager', 'SDR')" \
    --target-org "$SCRATCH_ALIAS" \
    --result-format human

echo ""
echo "--- Active Flows ---"
sf data query \
    --query "SELECT FullName, ActiveVersionId FROM FlowDefinition WHERE DeveloperName = 'Lead_Conversion_Task_Creation'" \
    --use-tooling-api \
    --target-org "$SCRATCH_ALIAS" \
    --result-format human

if [ "$WITH_SEED_DATA" = true ]; then
    echo ""
    echo "--- Record counts ---"
    sf data query --query "SELECT COUNT(Id) Accounts FROM Account" --target-org "$SCRATCH_ALIAS" --result-format human
    sf data query --query "SELECT COUNT(Id) Contacts FROM Contact" --target-org "$SCRATCH_ALIAS" --result-format human
    sf data query --query "SELECT COUNT(Id) Opportunities FROM Opportunity" --target-org "$SCRATCH_ALIAS" --result-format human
    sf data query --query "SELECT COUNT(Id) Leads FROM Lead" --target-org "$SCRATCH_ALIAS" --result-format human
fi

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
