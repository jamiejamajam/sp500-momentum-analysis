/*
=========================================================
Project: S&P 500 Momentum Investing Analysis

Author: James Parker

File:
01_dataset_validation.sql

Description:
This script performs initial validation checks on the
S&P 500 stock price database before any analysis begins.

Objectives:
• Verify the number of observations.
• Verify the number of companies.
• Confirm the dataset loaded correctly.

Dataset Summary:
• 187,343 daily stock price observations
• 30 representative S&P 500 companies
• Historical daily data from 2000 onwards

=========================================================
*/

-- ============================================================
-- Query 1: Verify dataset size
-- ============================================================

SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT symbol) AS total_companies
FROM sp500_stocks_selected;

-- Result:
-- Total observations: 187,343
-- Total companies: 30
-- Dataset loaded successfully into SQLite.

-- ============================================================
-- Query 2: Check for missing values
-- ============================================================

SELECT
    COUNT(*) AS total_rows,
    COUNT(date) AS dates,
    COUNT(open) AS open_prices,
    COUNT(high) AS high_prices,
    COUNT(low) AS low_prices,
    COUNT(close) AS close_prices,
    COUNT(volume) AS volumes,
    COUNT(symbol) AS symbols
FROM sp500_stocks_selected;

-- Result:
-- No missing values were found in the following columns:
-- date
-- open
-- high
-- low
-- close
-- volume
-- symbol

-- ============================================================
-- Query 3: Check for Duplicate Records
-- ============================================================

SELECT
    date,
    symbol,
    COUNT(*) AS duplicate_count
FROM sp500_stocks_selected
GROUP BY date, symbol
HAVING COUNT(*) > 1;

-- Result:
-- No duplicate (date, symbol) records were detected.
-- Each trading day contains only one record per company.

-- ============================================================
-- Query 4: Check Date Range
-- ============================================================

SELECT
    MIN(date) AS earliest_date,
    MAX(date) AS latest_date
FROM sp500_stocks_selected;

-- Result:
-- Earliest trading date: 2000-01-03
-- Latest trading date: 2026-06-22
-- The dataset spans over 26 years of historical trading data.

-- ============================================================
-- Query 5: Records per Company
-- ============================================================

SELECT
    symbol,
    COUNT(*) AS total_records
FROM sp500_stocks_selected
GROUP BY symbol
ORDER BY total_records DESC;

-- Result:
-- 30 companies returned.
-- Older companies contain approximately 6,656 observations.
-- Newer companies contain fewer observations because they entered
-- the S&P 500 or public markets later.

-- ============================================================
-- Query 6: Date Range per Company
-- ============================================================

SELECT
    symbol,
    MIN(date) AS first_trading_date,
    MAX(date) AS latest_trading_date,
    COUNT(*) AS total_records
FROM sp500_stocks_selected
GROUP BY symbol
ORDER BY first_trading_date;

-- Result:
-- Older companies begin on 2000-01-03.
-- Newer companies begin later due to IPO or later inclusion.
-- All companies should end on 2026-06-22.

-- =====================================================
-- Query 7: Average Closing Price by Company
-- =====================================================

SELECT
    symbol,
    ROUND(AVG(close), 2) AS average_close_price
FROM sp500_stocks_selected
GROUP BY symbol
ORDER BY average_close_price DESC;

-- Result:
-- 30 companies returned.
-- META recorded the highest average historical closing price ($232.85),
-- followed by COST ($204.78) and GS ($187.47).
-- NVDA recorded the lowest average historical closing price ($17.21),
-- reflecting its lower historical share price over much of the sample period.
-- Average closing prices vary substantially between companies, highlighting
-- differences in company maturity, valuation and historical price performance.

-- =====================================================
-- Query 8: Average Daily Trading Volume by Company
-- =====================================================

SELECT
    symbol,
    ROUND(AVG(volume), 0) AS average_daily_volume
FROM sp500_stocks_selected
GROUP BY symbol
ORDER BY average_daily_volume DESC;

-- Result:
-- 30 companies returned.
-- NVDA recorded the highest average daily trading volume
-- with approximately 591 million shares traded per day.
-- AAPL ranked second (368 million shares), followed by
-- AMZN (114 million shares) and GOOGL (110 million shares).
-- COST recorded the lowest average daily trading volume
-- at approximately 3.2 million shares per day.
-- Trading activity varies substantially across the selected companies,
-- reflecting differences in liquidity, investor interest and company size.

-- =====================================================
-- Query 9: Highest and Lowest Historical Closing Price
-- =====================================================

SELECT
    symbol,
    ROUND(MAX(close), 2) AS highest_close,
    ROUND(MIN(close), 2) AS lowest_close
FROM sp500_stocks_selected
GROUP BY symbol
ORDER BY highest_close DESC;

-- Result:
-- 30 companies returned.
-- GS recorded the highest historical closing price ($1,106.37),
-- followed by COST ($1,094.32) and CAT ($1,022.28).
-- PFE recorded the lowest maximum closing price ($48.25).
-- Several companies, including AAPL, AMZN and NVDA,
-- have very low historical minimum prices due to stock splits
-- and long-term growth over the sample period.
-- Historical price ranges vary substantially across companies,
-- highlighting differences in company growth, maturity and
-- share price history.

-- =====================================================
-- Query 10: Total Percentage Return by Company
-- =====================================================

WITH first_prices AS (
    SELECT
        symbol,
        MIN(date) AS first_date
    FROM sp500_stocks_selected
    GROUP BY symbol
),

last_prices AS (
    SELECT
        symbol,
        MAX(date) AS last_date
    FROM sp500_stocks_selected
    GROUP BY symbol
)

SELECT
    s1.symbol,
    s1.date AS first_date,
    ROUND(s1.close, 2) AS first_close,
    s2.date AS last_date,
    ROUND(s2.close, 2) AS last_close,
    ROUND(((s2.close - s1.close) / s1.close) * 100, 2) AS total_return_pct
FROM sp500_stocks_selected s1
JOIN first_prices fp
    ON s1.symbol = fp.symbol
    AND s1.date = fp.first_date
JOIN sp500_stocks_selected s2
    ON s1.symbol = s2.symbol
JOIN last_prices lp
    ON s2.symbol = lp.symbol
    AND s2.date = lp.last_date
ORDER BY total_return_pct DESC;

-- Result:
-- 30 companies returned.
-- NVDA generated the highest total return of 233,534.18%.
-- AAPL ranked second with a return of 35,354.39%.
-- GOOGL ranked third with 13,949.35%.
-- PFE recorded the lowest total return at 122.48%.
-- The results demonstrate substantial variation in long-term investment
-- performance across the selected S&P 500 companies.

-- =====================================================
-- Query 11: Annualized Return (CAGR) by Company
-- =====================================================

WITH first_prices AS (
    SELECT
        symbol,
        MIN(date) AS first_date
    FROM sp500_stocks_selected
    GROUP BY symbol
),

last_prices AS (
    SELECT
        symbol,
        MAX(date) AS last_date
    FROM sp500_stocks_selected
    GROUP BY symbol
)

SELECT
    s1.symbol,
    s1.date AS first_date,
    ROUND(s1.close, 2) AS first_close,
    s2.date AS last_date,
    ROUND(s2.close, 2) AS last_close,
    ROUND(
        (
            POWER(
                s2.close / s1.close,
                1.0 / ((julianday(s2.date) - julianday(s1.date)) / 365.25)
            ) - 1
        ) * 100,
        2
    ) AS cagr_pct
FROM sp500_stocks_selected s1
JOIN first_prices fp
    ON s1.symbol = fp.symbol
    AND s1.date = fp.first_date
JOIN sp500_stocks_selected s2
    ON s1.symbol = s2.symbol
JOIN last_prices lp
    ON s2.symbol = lp.symbol
    AND s2.date = lp.last_date
ORDER BY cagr_pct DESC;

-- Result:
-- 30 companies returned.
-- NVDA recorded the highest annualized return with a CAGR of 34.05%.
-- MA ranked second with a CAGR of 26.72%, followed by GOOGL at 25.41%.
-- AAPL ranked fourth with a CAGR of 24.83%.
-- PFE recorded the lowest CAGR at 3.07%.
-- CAGR provides a fairer comparison than total return because companies
-- have different starting dates within the dataset.

-- =====================================================
-- Query 12: Closing Price Volatility
-- =====================================================

SELECT
    symbol,
    ROUND(MAX(close) - MIN(close), 2) AS price_range
FROM sp500_stocks_selected
GROUP BY symbol
ORDER BY price_range DESC;

-- =====================================================
-- Query 12: Closing Price Volatility
-- =====================================================

SELECT
    symbol,
    ROUND(MAX(close) - MIN(close), 2) AS price_range
FROM sp500_stocks_selected
GROUP BY symbol
ORDER BY price_range DESC;

-- Result:
-- 30 companies returned.
-- COST recorded the widest historical price range ($1,076.17),
-- followed by GS ($1,067.97) and CAT ($1,014.33).
-- The historical price range varied substantially across companies,
-- indicating significant differences in long-term price movement.
-- This measure provides an initial indication of historical price
-- variation but should not be interpreted as statistical volatility.

