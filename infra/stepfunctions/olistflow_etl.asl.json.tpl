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
      "Seconds": 60,
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
      "Resource": "arn:aws:states:::aws-sdk:glue:startJobRun",
      "Parameters": {
        "JobName": "olistflow_etl_dev_raw_to_curated"
      },
      "Next": "WaitForRunRawToCurated"
    },
    "WaitForRunRawToCurated": {
      "Type": "Wait",
      "Seconds": 30,
      "Next": "GetRunRawToCurated"
    },
    "GetRunRawToCurated": {
      "Type": "Task",
      "Resource": "arn:aws:states:::aws-sdk:glue:getCrawler",
      "Parameters": {
        "Name": "olistflow_etl_dev_raw_to_curated"
      },
      "Next": "RawToCuratedDone?"
    },
    "RawToCuratedDone?": {
      "Type": "Choice",
      "Choices": [
        {
          "Variable": "$.Crawler.State",
          "StringEquals": "READY",
          "Next": "RunCuratedToRds"
        }
      ],
      "Default": "WaitForRunRawToCurated"
    },
    "RunCuratedToRds": {
      "Type": "Task",
      "Resource": "arn:aws:states:::aws-sdk:glue:startJobRun",
      "Parameters": {
        "JobName": "olistflow_etl_dev_curated_to_rds"
      },
      "End": true
    }
  }
}