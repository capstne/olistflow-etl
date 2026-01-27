{
  "Comment": "OlistFlow ETL: crawl raw -> raw_to_curated -> curated_to_rds",
  "StartAt": "StartRawCrawler",
  "States": {
    "StartRawCrawler": {
      "Type": "Task",
      "Resource": "arn:aws:states:::aws-sdk:glue:startCrawler",
      "Parameters": {
        "Name": "olistflow_etl_dev_raw_crawler"
      },
      "Next": "WaitForCrawler"
    },
    "WaitForCrawler": {
      "Type": "Wait",
      "Seconds": 30,
      "Next": "GetCrawler"
    },
    "GetCrawler": {
      "Type": "Task",
      "Resource": "arn:aws:states:::aws-sdk:glue:getCrawler",
      "Parameters": {
        "Name": "olistflow_etl_dev_raw_crawler"
      },
      "Next": "CrawlerDone?"
    },
    "CrawlerDone?": {
      "Type": "Choice",
      "Choices": [
        {
          "Variable": "$.Crawler.State",
          "StringEquals": "READY",
          "Next": "RunRawToCurated"
        }
      ],
      "Default": "WaitForCrawler"
    },
    "RunRawToCurated": {
      "Type": "Task",
      "Resource": "arn:aws:states:::glue:startJobRun.sync",
      "Parameters": {
        "JobName": "olistflow_etl_dev_raw_to_curated"
      },
      "Next": "RunCuratedToRds"
    },
    "RunCuratedToRds": {
      "Type": "Task",
      "Resource": "arn:aws:states:::glue:startJobRun.sync",
      "Parameters": {
        "JobName": "olistflow_etl_dev_curated_to_rds"
      },
      "End": true
    }
  }
}