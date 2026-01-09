{
  "Comment": "OlistFlow ETL: crawl raw -> raw_to_curated -> curated_to_rds",
  "StartAt": "StartRawCrawler",
  "States": {
    "StartRawCrawler": {
      "Type": "Task",
      "Resource": "arn:aws:states:::aws-sdk:glue:startCrawler",
      "Parameters": {
        "Name": "${crawler_name}"
      },
      "Next": "WaitForCrawler"
    },
    "WaitForCrawler": {
      "Type": "Wait",
      "Seconds": 15,
      "Next": "GetCrawler"
    },
    "GetCrawler": {
      "Type": "Task",
      "Resource": "arn:aws:states:::aws-sdk:glue:getCrawler",
      "Parameters": {
        "Name": "${crawler_name}"
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
        "JobName": "${raw_to_curated_job}"
      },
      "Next": "RunCuratedToRds"
    },
    "RunCuratedToRds": {
      "Type": "Task",
      "Resource": "arn:aws:states:::aws-sdk:glue:startJobRun",
      "Parameters": {
        "JobName": "${curated_to_rds_job}"
      },
      "End": true
    }
  }
}
