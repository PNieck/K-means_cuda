#include "Centroids.h"

#include <utility>
#include <iostream>

Centroids::Centroids() : Coordinates() {}

Centroids::Centroids(int centroids_cnt, int dim_cnt) : Coordinates(centroids_cnt, dim_cnt) {}

Centroids::Centroids(const Centroids& centroids) : Coordinates(centroids) {}

Centroids::Centroids(Centroids&& centroids) : Coordinates(std::move(centroids)) {}

Centroids& Centroids::operator=(const Centroids& centroids)
{
	(Coordinates&)*this = centroids;

	return *this;
}

Centroids& Centroids::operator=(Centroids&& centroids)
{
	(Coordinates&)*this = std::move(centroids);

	return *this;
}

Centroids::~Centroids() {}


void Centroids::print()
{
	std::cout << std::endl;
	std::cout << "Centroids:" << std::endl;

	Coordinates::print();
}
