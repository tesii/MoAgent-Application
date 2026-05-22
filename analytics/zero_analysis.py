import pandas as pd  # type: ignore

# Define file paths
input_file_path = r"C:\Users\DELL\Documents\patience_data_encry.csv"
output_file_path = r"C:\Users\DELL\Documents\patience_data_encry_cleaned.csv"

# Define columns to check
columns_to_check = ['Province', 'District', 'Sector']

# Chunk size (adjust based on your memory capacity)
chunk_size = 4500000  # Process 2,000,000 rows at a time

# Initialize counters
total_rows = 0
cleaned_rows = 0
rows_removed = 0
first_chunk = True

print("Processing dataset in chunks...")
print(f"Using chunk size: {chunk_size}")  # Debug: Confirm chunk_size

# Read and process the CSV file in chunks
for chunk in pd.read_csv(input_file_path, chunksize=chunk_size):
    print(f"Chunk size received: {len(chunk)}")  # Debug: Check actual chunk size
    # Check if all required columns exist in the chunk
    if all(column in chunk.columns for column in columns_to_check):
        # Create condition to identify rows where ALL specified columns are "0"
        all_zeros_condition = True
        for column in columns_to_check:
            all_zeros_condition = all_zeros_condition & (chunk[column] == "0")
        
        # Count rows in this chunk
        chunk_rows = len(chunk)
        total_rows += chunk_rows
        
        # Count rows to be removed in this chunk
        chunk_rows_to_remove = chunk[all_zeros_condition].shape[0]
        rows_removed += chunk_rows_to_remove
        
        # Clean the chunk by removing rows where all specified columns are "0"
        cleaned_chunk = chunk[~all_zeros_condition].copy()
        cleaned_rows += len(cleaned_chunk)
        
        # Write the cleaned chunk to the output file
        if first_chunk:
            # For the first chunk, write with headers
            cleaned_chunk.to_csv(output_file_path, mode='w', index=False)
            first_chunk = False
        else:
            # For subsequent chunks, append without headers
            cleaned_chunk.to_csv(output_file_path, mode='a', header=False, index=False)
        
        print(f"Processed chunk: {chunk_rows} rows, Removed: {chunk_rows_to_remove}, Kept: {len(cleaned_chunk)}")
    else:
        print("One or more specified columns not found in chunk. Skipping chunk.")
        break

# Final summary
print("\nCleaning complete!")
print(f"Total rows processed: {total_rows}")
print(f"Total rows removed: {rows_removed}")
print(f"Total rows kept: {cleaned_rows}")
print(f"Cleaned data saved to: {output_file_path}")
