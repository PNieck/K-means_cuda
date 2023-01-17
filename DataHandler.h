#pragma once

#include "Points.h"
#include "Centroids.h"

#include <string>

static class DataHandler
{
public:
	void static Deserialize(const std::string& path, Points& points, Centroids& centroids);
	void static Serialize(const std::string& path, const Points& points, const Centroids& centroids);
};

