import pandas as pd
import matplotlib.pyplot as plt
import os

def generate_multi_file_report(output_image_path):
    """
    Reads multiple semicolon-separated CSV files from the current directory,
    plots 'Open Issues' and 'Open PRs' for each, and saves the plots
    to a single image file.

    Parameters:
    - output_image_path: The path where the output image will be saved.
    """
    # List of all the files to be processed
    file_list = [
        'camel-tooling-camel-dap-client-vscode.csv',
        'camel-tooling-camel-debug-adapter.csv',
        'camel-tooling-camel-language-server.csv',
        'camel-tooling-camel-lsp-client-vscode.csv',
        'camel-tooling-vscode-camel-extension-pack.csv'
    ]

    # Create a figure with a subplot for each file
    # We set the number of rows to the number of files and 1 column
    # The figsize is adjusted to accommodate all subplots
    num_files = len(file_list)
    fig, axes = plt.subplots(nrows=num_files, ncols=1, figsize=(12, 5 * num_files))
    
    # This ensures axes is an iterable even for a single file case
    if num_files == 1:
        axes = [axes]

    print(f"Processing {num_files} CSV files...")
    
    for i, file_name in enumerate(file_list):
        file_path = os.path.join(os.getcwd(), file_name)

        # Check if the file exists before attempting to read it
        if not os.path.exists(file_path):
            print(f"Warning: File '{file_path}' not found. Skipping.")
            continue
        
        try:
            # Read the CSV file using a semicolon as the separator
            df = pd.read_csv(file_path, sep=';')

            # Convert the 'Date' column to a proper datetime format
            df['Date'] = pd.to_datetime(df['Date'])
            
            # Sort the DataFrame by date to ensure the line plot is correct
            df.sort_values(by='Date', inplace=True)

            # Select the correct subplot to plot on
            ax = axes[i]
            
            # Plot both 'Open Issues' and 'Open PRs' on the current subplot
            ax.plot(df['Date'], df['Open Issues'], label='Open Issues', marker='o')
            ax.plot(df['Date'], df['Open PRs'], label='Open PRs', marker='o')

            # Set a title based on the filename and add labels/legend
            ax.set_title(f'Metrics for {file_name.replace(".csv", "")}')
            ax.set_xlabel('Date')
            ax.set_ylabel('Count')
            ax.legend()
            ax.grid(True)
            
            # Rotate x-axis labels for readability
            plt.sca(ax)
            plt.xticks(rotation=45, ha='right')

        except Exception as e:
            print(f"An error occurred while processing '{file_name}': {e}")
            
    # Adjust the spacing between subplots to prevent titles from overlapping
    plt.tight_layout()

    # Save the final figure with all subplots
    plt.savefig(output_image_path)
    print(f"\nFinal plot saved successfully to {output_image_path}")

if __name__ == "__main__":
    output_image_name = 'combined_metrics_report.png'
    generate_multi_file_report(output_image_name)