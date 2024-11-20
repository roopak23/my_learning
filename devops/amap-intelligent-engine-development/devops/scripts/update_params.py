import yaml
from sys import argv


def main(param_file, file_to_replace, file_to_replace_new):
    with open(param_file, "r") as stream:
        dict = yaml.safe_load(stream)
    
  
    

    with open(file_to_replace, "r") as stream:
        data = stream.read()
        if  dict["params"]:
          for item in dict["params"]:
              data = data.replace(item["name"], str(item["value"]))

    with open(file_to_replace_new, "w") as stream:
        stream.write(data)
    return 0


# Templated variables
if __name__ == "__main__":
    # Table

    param_file = argv[1]
    file_to_replace = argv[2]
    
    file_to_replace_new = argv[3]

    main(param_file, file_to_replace, file_to_replace_new)