#!/bin/sh

# Set environment variables
export PGPASSWORD=postgrespass
export PGSSLMODE=prefer

# Define the database connection parameters
HOST="my-postgres-db.cn4ugcqmu5zd.us-east-1.rds.amazonaws.com"
PORT=5432
USER="postgres"
DBNAME="gantt"

# Loop until the connection is successful
while true; do
  echo "Attempting to connect to PostgreSQL database..."

  # Try to connect to the database
  psql -h $HOST -p $PORT -U $USER -d $DBNAME -c '\q'

  # Check the exit status of the psql command
  if [ $? -eq 0 ]; then
    echo "Connection successful!"
    break
  else
    echo "Connection failed. Retrying in 5 seconds..."
    sleep 5
  fi
done