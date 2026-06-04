def make_single_line(input_filename, output_filename):
    with open(input_filename, 'r', encoding='utf-8') as infile:
        # Read all lines, strip the whitespace/newlines from edges, and join them together
        single_line_content = "".join(line.strip() for line in infile)
        
    with open(output_filename, 'w', encoding='utf-8') as outfile:
        outfile.write(single_line_content)

# Run the function
make_single_line('e.svg', 'Romania_Motorways_DE_1.svg')
print("Done!")
