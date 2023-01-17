#!/usr/bin/env python

import random
import argparse
import json

from typing import List

DESCRIPTION = "Program is generating data for K-means algorithm. The result is a JSON file with n-dimensions points.\
These points are divided into groups using normal distribution."


def handle_arguments():
    parser = argparse.ArgumentParser(
        prog = "K-means data generator",
        description = DESCRIPTION
    )
    parser.add_argument("-g", "--centroids", default=5, type=int, help="How many centroids should be generated", dest="centroids_cnt")
    parser.add_argument("-p", "--points", default=1_000_000, type=int, help="How many points should be generated", dest="points_cnt")
    parser.add_argument("-c", "--coordinates", default=3, type=int, help="How many coordinates points should have", dest="coord_cnt")
    parser.add_argument("-a", "--max", default=10_000, type=int, help="Max value of point dimension", dest="max_coord")
    parser.add_argument("-i", "--min", default=-10_000, type=int, help="Min value of point dimension", dest="min_coord")

    return parser.parse_args()


def create_centroid(size: int, min, max):
    return [random.uniform(min, max) for  _ in range(size)]


def create_point(centroid_coord: List, sigma: float):
    size = len(centroid_coord)
    return [random.gauss(centroid_coord[i], sigma) for i in range(size)]


def main():
    args = handle_arguments()

    centroids = []
    for _ in range(args.centroids_cnt):
        centroids.append(create_centroid(args.coord_cnt, args.min_coord, args.max_coord))
    
    belongings = []     # stores which point belong to which centroid
    for _ in range(args.points_cnt):
        belongings.append(random.randint(0, args.centroids_cnt - 1))

    coordinates = []
    for i in range(args.points_cnt):
        centroid = centroids[belongings[i]]
        coordinates.append(create_point(centroid, 100))

    points = []
    for i in range(args.points_cnt):
        points.append({
            "centroid" : belongings[i],
            "coordinates": coordinates[i]
        })
    
    json_data = {
        "coord_cnt": args.coord_cnt,
        "centroids": centroids,
        "points": points
    }

    with open('input_data.json', 'w') as file:
        json.dump(json_data, file, indent=2)


if __name__ == "__main__":
    main()
