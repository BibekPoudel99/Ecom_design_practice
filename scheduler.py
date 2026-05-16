from apscheduler.schedulers.blocking import BlockingScheduler
from main import run_pipeline

scheduler = BlockingScheduler()

# Run every day at 2AM
scheduler.add_job(run_pipeline, "cron", hour=2, minute=0)

print("Scheduler started. Pipeline runs daily at 2AM. Ctrl+C to stop.")

try:
    run_pipeline()          # run once immediately on start
    scheduler.start()
except KeyboardInterrupt:
    print("Scheduler stopped.")