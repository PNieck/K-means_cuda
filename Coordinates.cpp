#include "Includes/Coordinates.h"

#include <iostream>

Coordinates::Coordinates()
{
	this->cnt = 0;
	this->dim_cnt = 0;

	this->coordinates = nullptr;
}


Coordinates::Coordinates(int size, int dim_cnt)
{
	this->cnt = size;
	this->dim_cnt = dim_cnt;

	this->coordinates = new float* [dim_cnt];

	for (int i = 0; i < dim_cnt; i++) {
		this->coordinates[i] = new float[size];
	}
}


Coordinates::Coordinates(const Coordinates& coordinates)
{
	this->cnt = coordinates.cnt;
	this->dim_cnt = coordinates.dim_cnt;

	this->coordinates = new float* [dim_cnt];

	for (int i = 0; i < dim_cnt; i++) {
		this->coordinates[i] = new float[cnt];
	}

	RewriteValues(coordinates);
}


Coordinates::Coordinates(Coordinates&& coordinates)
{
	this->cnt = coordinates.cnt;
	this->dim_cnt = coordinates.dim_cnt;
	this->coordinates = coordinates.coordinates;

	coordinates.coordinates = nullptr;
}


Coordinates& Coordinates::operator=(const Coordinates& coordinates)
{
	if (this != &coordinates)
	{
		if (this->cnt != coordinates.cnt || this->dim_cnt != coordinates.dim_cnt)
		{
			this->~Coordinates();

			this->cnt = coordinates.cnt;
			this->dim_cnt = coordinates.dim_cnt;

			this->coordinates = new float* [dim_cnt];

			for (int i = 0; i < dim_cnt; i++) {
				this->coordinates[i] = new float[cnt];
			}
		}

		RewriteValues(coordinates);
	}

	return *this;
}


Coordinates& Coordinates::operator=(Coordinates&& coordinates)
{
	if (this != &coordinates)
	{
		this->cnt = coordinates.cnt;
		this->dim_cnt = coordinates.dim_cnt;
		this->coordinates = coordinates.coordinates;

		coordinates.coordinates = nullptr;
	}

	return *this;
}


Coordinates::~Coordinates()
{
	if (coordinates == nullptr)
		return;

	for (int i = 0; i < dim_cnt; i++) {
		delete[] this->coordinates[i];
	}

	delete[] coordinates;
}


void Coordinates::clear_coord()
{
	for (int i = 0; i < cnt; i++) {
		for (int j = 0; j < dim_cnt; j++) {
			coordinates[j][i] = 0;
		}
	}
}


void Coordinates::print()
{
	for (int i = 0; i < cnt; i++) {
		std::cout << i << ".: (";

		for (int j = 0; j < dim_cnt; j++) {
			std::cout << coordinates[j][i] << " ";
		}

		std::cout << ")" << std::endl;
	}
}


void Coordinates::RewriteValues(const Coordinates& coordinates)
{
	for (int i = 0; i < dim_cnt; i++) {
		for (int j = 0; j < cnt; j++) {
			this->coordinates[i][j] = coordinates.coordinates[i][j];
		}
	}
}
