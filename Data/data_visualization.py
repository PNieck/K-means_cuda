import json
import matplotlib


def main():


    with open("input_data.json", "r") as file:
        data = file.read()
    
    data = json(data)



if __name__ == "__main__":
    main()
