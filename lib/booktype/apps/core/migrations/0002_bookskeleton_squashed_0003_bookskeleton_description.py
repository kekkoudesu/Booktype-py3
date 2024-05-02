# -*- coding: utf-8 -*-
# Generated by Django 1.9.12 on 2017-08-21 21:45
from __future__ import unicode_literals

from django.db import migrations, models
import django.db.models.deletion


class Migration(migrations.Migration):

    replaces = [('core', '0002_bookskeleton'), ('core', '0003_bookskeleton_description')]

    dependencies = [
        ('core', '0001_initial'),
        ('editor', '0009_chapter_content_json'),
    ]

    operations = [
        migrations.CreateModel(
            name='BookSkeleton',
            fields=[
                ('id', models.AutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('name', models.CharField(max_length=100, verbose_name='Name')),
                ('skeleton_type', models.IntegerField(choices=[(1, 'EPUB')], verbose_name='Skeleton Type')),
                ('skeleton_file', models.FileField(upload_to='book_skeletons/', verbose_name='File')),
                ('language', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, to='editor.Language', verbose_name='Language')),
                ('description', models.CharField(blank=True, max_length=255, verbose_name='description')),
            ],
            options={
                'verbose_name': 'Book Skeleton',
                'verbose_name_plural': 'Book Skeletons',
            },
        ),
    ]
