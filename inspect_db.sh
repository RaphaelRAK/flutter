#!/bin/bash

# Script pour inspecter la base de données SQLite de l'application Flut Budget

PACKAGE_NAME="com.example.flut_budget"
DB_NAME="budget.db"

echo "🔍 Recherche de la base de données..."
echo ""

# Vérifier si on est sur Android ou iOS
if command -v adb &> /dev/null; then
    # Android
    echo "📱 Plateforme: Android"
    echo ""
    
    # Vérifier si un appareil est connecté
    if ! adb devices | grep -q "device$"; then
        echo "❌ Aucun appareil Android connecté"
        echo "   Connectez un émulateur ou un appareil physique"
        exit 1
    fi
    
    # Trouver le chemin de la base de données
    DB_PATH=$(adb shell "run-as $PACKAGE_NAME find /data/data/$PACKAGE_NAME -name $DB_NAME 2>/dev/null" | head -1)
    
    if [ -z "$DB_PATH" ]; then
        echo "❌ Base de données non trouvée"
        echo "   Assurez-vous que l'application a été lancée au moins une fois"
        exit 1
    fi
    
    echo "✅ Base de données trouvée: $DB_PATH"
    echo ""
    echo "📋 Options disponibles:"
    echo "   1. Copier la base de données localement"
    echo "   2. Ouvrir avec sqlite3 (interactif)"
    echo "   3. Afficher les tables"
    echo "   4. Afficher le contenu d'une table"
    echo ""
    read -p "Choisissez une option (1-4) ou appuyez sur Entrée pour copier: " choice
    
    case $choice in
        2)
            echo "🔧 Ouverture de sqlite3..."
            adb shell "run-as $PACKAGE_NAME sqlite3 $DB_PATH"
            ;;
        3)
            echo "📊 Tables disponibles:"
            adb shell "run-as $PACKAGE_NAME sqlite3 $DB_PATH '.tables'"
            ;;
        4)
            echo "📊 Tables disponibles:"
            adb shell "run-as $PACKAGE_NAME sqlite3 $DB_PATH '.tables'"
            echo ""
            read -p "Nom de la table à afficher: " table_name
            if [ ! -z "$table_name" ]; then
                echo ""
                echo "📋 Contenu de la table $table_name:"
                adb shell "run-as $PACKAGE_NAME sqlite3 $DB_PATH 'SELECT * FROM $table_name;'"
            fi
            ;;
        *)
            # Par défaut: copier la base de données
            LOCAL_DB="./budget.db"
            echo "📥 Copie de la base de données vers: $LOCAL_DB"
            adb shell "run-as $PACKAGE_NAME cat $DB_PATH" > "$LOCAL_DB"
            echo "✅ Base de données copiée!"
            echo ""
            echo "💡 Vous pouvez maintenant l'inspecter avec:"
            echo "   sqlite3 $LOCAL_DB"
            echo ""
            echo "📋 Commandes utiles sqlite3:"
            echo "   .tables          - Liste les tables"
            echo "   .schema          - Affiche le schéma"
            echo "   SELECT * FROM transactions;  - Affiche toutes les transactions"
            echo "   .quit            - Quitter"
            ;;
    esac
    
else
    # iOS Simulator
    echo "📱 Plateforme: iOS Simulator"
    echo ""
    echo "🔍 Recherche dans les simulateurs iOS..."
    
    # Trouver les simulateurs disponibles
    SIMULATORS=$(xcrun simctl list devices | grep "Booted" | head -1)
    
    if [ -z "$SIMULATORS" ]; then
        echo "❌ Aucun simulateur iOS en cours d'exécution"
        echo "   Lancez l'application dans le simulateur iOS"
        exit 1
    fi
    
    echo "✅ Simulateur trouvé"
    echo ""
    echo "💡 Pour iOS, vous devez trouver le chemin manuellement:"
    echo "   ~/Library/Developer/CoreSimulator/Devices/[DEVICE_ID]/data/Containers/Data/Application/[APP_ID]/Documents/$DB_NAME"
    echo ""
    echo "   Ou utilisez cette commande pour lister les apps:"
    echo "   xcrun simctl get_app_container booted $PACKAGE_NAME"
    echo ""
fi






