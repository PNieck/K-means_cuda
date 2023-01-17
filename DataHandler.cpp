#include "DataHandler.h"

#include <fstream>

#include "JsonCpp/json/json.h"

void DataHandler::Deserialize(const std::string& path, Points& points, Centroids& centroids)
{
	std::ifstream input(path);
	if (!input.good()) {
		throw std::invalid_argument("Cannot open file: " + path);
	}

	Json::Reader reader;
	Json::Value data;

	if (!reader.parse(input, data)) {
		throw std::invalid_argument("File: " + path + " contains invalid JSON file");
	}

	input.close();

	int centroids_cnt = data["centroids"].size();
	int points_cnt = data["points"].size();
	int dim_cnt = data["coord_cnt"].asInt();

	points = std::move(Points(points_cnt, dim_cnt));
	centroids = std::move(Centroids(centroids_cnt, dim_cnt));

	for (int i = 0; i < centroids_cnt; i++) {
		for (int j = 0; j < dim_cnt; j++)
		{
			float f = data["centroids"][i][j].asFloat();
			centroids.coordinates[j][i] = f;
		}
	}
	
	for (int i = 0; i < points_cnt; i++) {
		for (int j = 0; j < dim_cnt; j++)
			points.coordinates[j][i] = data["points"][i]["coordinates"][j].asFloat();

		points.centroids_indexes[i] = data["points"][i]["centroid"].asInt();
	}
}


Json::Value SerializePoints(const Points& points)
{
	Json::Value points_arr(Json::arrayValue);
	Json::Value one_point;
	Json::Value point_coord(Json::arrayValue);

	for (int i = 0; i < points.cnt; i++)
	{
		for (int j = 0; j < points.dim_cnt; j++)
		{
			point_coord.append(points.coordinates[j][i]);
		}

		one_point["centroid"] = points.centroids_indexes[i];
		one_point["coordinates"] = point_coord;
		point_coord.clear(); 

		points_arr.append(one_point);
	}

	return points_arr;
}


Json::Value SerializeCentroids(const Centroids& centroids)
{
	Json::Value centroids_arr(Json::arrayValue);
	Json::Value centroids_coord(Json::arrayValue);

	for (int i = 0; i < centroids.cnt; i++)
	{
		for (int j = 0; j < centroids.dim_cnt; j++)
		{
			centroids_coord.append(centroids.coordinates[j][i]);
		}

		centroids_arr.append(centroids_coord);
		centroids_coord.clear();
	}

	centroids_coord.clear();
	return centroids_arr;
}


void DataHandler::Serialize(const std::string& path, const Points& points, const Centroids& centroids)
{
	Json::Value result;

	result["coord_cnt"] = points.dim_cnt;
	result["centroids"] = SerializeCentroids(centroids);
	result["points"] = SerializePoints(points);

	std::ofstream output(path);

	if (!output.good()) {
		throw std::invalid_argument("Cannot open file: " + path);
	}

	output << result;

	output.close();
}
