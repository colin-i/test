def make_readable(input_filename, output_filename):
    with open(input_filename, 'r', encoding='utf-8') as infile:
        content = infile.read()
    
    # Replace every '<' with a newline followed by '<'
    # .lstrip() ensures we don't accidentally add a blank line at the very beginning
    formatted_content = content.replace('<', '\n<').lstrip()
    
    with open(output_filename, 'w', encoding='utf-8') as outfile:
        outfile.write(formatted_content)

# Run the function
make_readable('Romania_Motorways_DE_1.svg', 'e.svg')
print("Done!")
