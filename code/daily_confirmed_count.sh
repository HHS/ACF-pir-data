# Runs daily via crontab
# Command 00 08 * * * /bin/bash <path-to-this-script>
python3.12 -m pir_pipeline.dashboard.scripts.daily_confirmed
