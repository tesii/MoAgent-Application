
import pandas as pd
import matplotlib.pyplot as plt
import os
import numpy as np
from datetime import datetime

# Define the path to the CSV file
file_path = "\\Users\\DELL\\Documents\\patience_data_encry_cleaned.csv"

# Define output PNG path only
output_plot_file = "\\Users\\DELL\\Documents\\nyarugenge_cash_flow_analysis.png"

# Define chunk size
chunk_size = 19000000

# Define columns
sector_col = 'Sector'
district_col = 'District'
province_col = 'Province'
cash_in_col = 'CASH_IN_AMOUNT'
cash_out_col = 'CASH_OUT_AMOUNT'

# Function to clean and standardize text data for consistency
def standardize_text(df, columns):
    for col in columns:
        if col in df.columns and df[col].dtype == object:
            df[col] = df[col].str.upper().str.strip()
    return df

# Check if file exists
if not os.path.exists(file_path):
    print(f"Error: File not found at {file_path}")
    exit(1)

# Count total rows for progress tracking
try:
    total_rows = sum(1 for _ in open(file_path)) - 1
    print(f"Total rows to process: {total_rows:,}")
except Exception as e:
    print(f"Warning: Couldn't count rows: {str(e)}")
    total_rows = 0

# Track start time for performance monitoring
start_time = datetime.now()
processed_rows = 0

print(f"Processing CSV file in chunks of {chunk_size:,} rows...")

# Initialize cash summary dataframe
cash_summary = pd.DataFrame()

try:
    for chunk_num, chunk in enumerate(pd.read_csv(file_path, chunksize=chunk_size)):
        # Update processed rows count
        chunk_len = len(chunk)
        processed_rows += chunk_len
        
        # Progress reporting
        if total_rows > 0:
            percent_complete = (processed_rows/total_rows)*100
            print(f"Chunk {chunk_num+1}: Processed {processed_rows:,} of {total_rows:,} rows ({percent_complete:.1f}%)")
        else:
            print(f"Chunk {chunk_num+1}: Processed {processed_rows:,} rows")
        
        # Check if required columns exist
        required_cols = [sector_col, district_col, province_col, cash_in_col, cash_out_col]
        if not all(col in chunk.columns for col in required_cols):
            missing = [col for col in required_cols if col not in chunk.columns]
            print(f"Error: Missing columns {missing}. Please check your CSV.")
            break
        
        # Standardize text columns (capitalize)
        chunk = standardize_text(chunk, [sector_col, district_col, province_col])
        
        # Clean numeric columns
        for col in [cash_in_col, cash_out_col]:
            chunk[col] = pd.to_numeric(chunk[col], errors='coerce')
            chunk[col].fillna(0, inplace=True)
        
        # Filter for Nyarugenge District in Kigali Province
        filtered_chunk = chunk[(chunk[district_col] == 'NYARUGENGE') & 
                              (chunk[province_col] == 'KIGALI')]
        
        if not filtered_chunk.empty:
            # Group by Sector and calculate sums for this chunk
            chunk_summary = filtered_chunk.groupby(sector_col).agg({
                cash_in_col: 'sum',
                cash_out_col: 'sum'
            }).reset_index()
            
            # Append to the main cash_summary DataFrame
            cash_summary = pd.concat([cash_summary, chunk_summary])

    # After processing all chunks, aggregate the results
    if not cash_summary.empty:
        # Final aggregation across all chunks
        cash_summary = cash_summary.groupby(sector_col).agg({
            cash_in_col: 'sum',
            cash_out_col: 'sum'
        }).reset_index()
        
        # Calculate net cash flow
        cash_summary['Net Cash Flow'] = cash_summary[cash_in_col] - cash_summary[cash_out_col]
        
        # Rename columns for clarity
        cash_summary.columns = ['Sector', 'Total Cash In', 'Total Cash Out', 'Net Cash Flow']
        
        # Sort by Net Cash Flow for better insights
        cash_summary = cash_summary.sort_values('Net Cash Flow', ascending=False)
        
        # Print the summary table
        print("\nCash Summary by Sector in Nyarugenge District, Kigali:")
        print(cash_summary)
        
        # Print run statistics
        end_time = datetime.now()
        duration = (end_time - start_time).total_seconds()
        print(f"\nExecution completed in {duration:.2f} seconds")
        print(f"Processed {processed_rows:,} total rows")
        print(f"Found {len(cash_summary)} sectors in Nyarugenge District")
        
        # Create visualizations
        plt.figure(figsize=(12, 8))
        
        # Set the positions of the bars on the x-axis
        x = np.arange(len(cash_summary))
        width = 0.35
        
        # Create the bar plots
        ax = plt.subplot(211)
        bars1 = ax.bar(x - width/2, cash_summary['Total Cash In'], width, label='Cash In')
        bars2 = ax.bar(x + width/2, cash_summary['Total Cash Out'], width, label='Cash Out')
        
        # Add labels and title
        ax.set_xlabel('Sector')
        ax.set_ylabel('Amount')
        ax.set_title('Total Cash In and Cash Out by Sector in Nyarugenge District, Kigali')
        ax.set_xticks(x)
        ax.set_xticklabels(cash_summary['Sector'], rotation=45, ha='right')
        ax.legend()
        
        # Add a second subplot for Net Cash Flow
        ax2 = plt.subplot(212)
        colors = ['green' if x >= 0 else 'red' for x in cash_summary['Net Cash Flow']]
        bars3 = ax2.bar(x, cash_summary['Net Cash Flow'], width, color=colors)
        
        # Add labels and title for second subplot
        ax2.set_xlabel('Sector')
        ax2.set_ylabel('Amount')
        ax2.set_title('Net Cash Flow by Sector (Positive = Cash In > Cash Out)')
        ax2.set_xticks(x)
        ax2.set_xticklabels(cash_summary['Sector'], rotation=45, ha='right')
        
        # Add values on top of the bars for better readability
        def add_labels(bars):
            for bar in bars:
                height = bar.get_height()
                ax2.annotate(f'{height:,.0f}',
                            xy=(bar.get_x() + bar.get_width() / 2, height),
                            xytext=(0, 3),  # 3 points vertical offset
                            textcoords="offset points",
                            ha='center', va='bottom', rotation=90)
        
        add_labels(bars3)
        
        plt.tight_layout()
        plt.savefig(output_plot_file)
        print(f"Visualization saved to: {output_plot_file}")
        plt.show()
        
        # Display the effect of standardization
        print("\nEffect of standardization:")
        print(f"Number of unique sectors after standardization: {len(cash_summary)}")
        
    else:
        print("No data available for Nyarugenge District, Kigali.")

except Exception as e:
    print(f"Error processing file: {str(e)}")
    import traceback
    traceback.print_exc()
